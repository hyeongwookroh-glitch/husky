#!/bin/bash
# PreToolUse hook — inject B2B mention reminder whenever mcp__husky__reply is called.
#
# 정책: 매 호출마다 additionalContext 로 리마인더 주입. 차단 안 함.
# 어시스턴트는 리마인더를 받고 대화 맥락 재평가 후 멘션 포함 여부 판단.
#
# Discord 기본은 인간 1:1 DM/채널이라 멘션 불필요한 경우가 대부분이지만,
# 다른 봇과 relay 구성 시 멘션 누락을 방지한다.
# KNOWN_BOTS 는 설치 시 페르소나/환경에 맞게 채운다.

INPUT=$(cat)

python3 - "$INPUT" <<'PY'
import json, re, sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)

if payload.get("tool_name", "") != "mcp__husky__reply":
    sys.exit(0)

tool_input = payload.get("tool_input", {}) or {}
channel_id = tool_input.get("channelId", "")
text = tool_input.get("text", "") or ""

# Discord mention format: <@123456789012345678>
mentions = re.findall(r"<@!?(\d{17,20})>", text)

# 다른 봇과의 relay 구성 시 여기를 채운다. (Discord user ID)
KNOWN_BOTS = {
    # "000000000000000000": "ExampleBot",
}

mentioned_bots = [KNOWN_BOTS[uid] for uid in mentions if uid in KNOWN_BOTS]
missing_bot_ids = [f"{name}: <@{uid}>" for uid, name in KNOWN_BOTS.items() if uid not in mentions]

if not KNOWN_BOTS:
    sys.exit(0)

lines = [
    "B2B 멘션 체크 리마인더 (mcp__husky__reply 호출 감지)",
    "",
    "현재 대화 상대가 다른 봇이라면 반드시 그 봇의 `<@봇ID>` 멘션이 text 에 포함돼야 메시지가 전달된다.",
    "인간 대상 DM/채널이면 멘션 불필요 — 판단은 대화 맥락으로.",
    "",
    f"- channelId: {channel_id}",
    f"- text 내 발견된 멘션: {mentions if mentions else '없음'}",
]

if mentioned_bots:
    lines.append(f"- 포함된 알려진 봇: {', '.join(mentioned_bots)}")
lines.append(f"- 아직 멘션 안 된 알려진 봇: {', '.join(missing_bot_ids) if missing_bot_ids else '없음'}")
lines.append("")
lines.append(
    "만약 이 reply 의 의도된 수신자가 위 '아직 멘션 안 된 봇' 중에 있는데 멘션을 빠트렸다면, "
    "지금 즉시 reply tool 을 재호출해 해당 `<@봇ID>` 를 text 에 포함해 다시 보낼 것. "
    "인간만 대상이거나 이미 올바른 봇이 멘션되어 있으면 추가 액션 불필요."
)

reminder = "\n".join(lines)

out = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "additionalContext": reminder,
    }
}
sys.stdout.write(json.dumps(out, ensure_ascii=False))
PY
