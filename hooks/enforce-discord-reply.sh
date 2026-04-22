#!/bin/bash
# Stop hook — block turn-end if any Discord (husky MCP) message in this transcript
# has no subsequent mcp__husky__reply / mcp__husky__dismiss tool call
# before end-of-transcript.
#
# transcript 전체를 스캔해 compact 이후 summary user 주입이나 CLI 메시지가
# 끼어들어도 직전 Discord 미답변을 놓치지 않도록 한다.

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))")
STOP_ACTIVE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('stop_hook_active', False))")

if [ "$STOP_ACTIVE" = "True" ]; then
  exit 0
fi

if [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

python3 - "$TRANSCRIPT_PATH" <<'PY'
import json, re, sys

path = sys.argv[1]

try:
    with open(path) as f:
        lines = f.readlines()
except Exception:
    sys.exit(0)

CHANNEL_RE = re.compile(
    r'channel source="husky".*?messageTs="(\d{15,})"',
    re.DOTALL,
)

discord_msgs = []  # list of (line_idx, messageTs)
reply_idxs = []    # list of line_idx where reply/dismiss tool_use appears

for i, line in enumerate(lines):
    try:
        e = json.loads(line)
    except Exception:
        continue
    t = e.get('type')
    msg = e.get('message', {}) or {}

    if t == 'user':
        content = msg.get('content', '')
        if isinstance(content, list):
            # tool_result 는 user 타입이지만 실제 사용자 발화가 아님 — 스킵
            if any(isinstance(b, dict) and b.get('type') == 'tool_result' for b in content):
                continue
            text = json.dumps(content, ensure_ascii=False)
        else:
            text = str(content)
        m = CHANNEL_RE.search(text)
        if m:
            discord_msgs.append((i, m.group(1)))

    elif t == 'assistant':
        for block in msg.get('content', []) or []:
            if not isinstance(block, dict):
                continue
            if block.get('type') == 'tool_use' and block.get('name') in (
                'mcp__husky__reply',
                'mcp__husky__dismiss',
            ):
                reply_idxs.append(i)
                break

if not discord_msgs:
    sys.exit(0)

# 규칙: "가장 최근 reply/dismiss 이후 도착한 Discord msg는 모두 미답변".
# 이전까지는 최근 reply 하나로 다 대응된 것으로 간주.
last_reply_idx = reply_idxs[-1] if reply_idxs else -1
unanswered = [ts for idx, ts in discord_msgs if idx > last_reply_idx]

if not unanswered:
    sys.exit(0)

sys.stderr.write(
    "BLOCK: 미답변 Discord 메시지 {n}건 (messageTs: {ts}). "
    "mcp__husky__reply 또는 mcp__husky__dismiss로 처리한 뒤 종료하라.\n".format(
        n=len(unanswered),
        ts=", ".join(unanswered[:5]) + (" …" if len(unanswered) > 5 else ""),
    )
)
sys.exit(2)
PY
