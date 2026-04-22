#!/bin/bash
# PostCompact hook — re-inject critical context after context compaction

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HUSKY_MEMORY="${HUSKY_MEMORY_DIR:-$HOME/Documents/Husky_Memory}"
SESSION_DIR="$HUSKY_MEMORY/session_notes/husky"
MEMORY_DIR="$REPO_ROOT/.claude/memory"

echo "=== [Husky PostCompact Recovery] ==="
echo ""

# 1. Core persona
echo "## Core Persona"
echo ""
cat "$REPO_ROOT/CLAUDE.md"
echo ""

# 2. Checkpoint FIRST (working state)
for cp in "$HUSKY_MEMORY/checkpoint.md" "$MEMORY_DIR/checkpoint.md"; do
  if [ -f "$cp" ]; then
    echo "## Checkpoint (recovered — act on this IMMEDIATELY)"
    echo ""
    cat "$cp"
    echo ""
    rm "$cp"
    break
  fi
done

# 3. Session notes (today)
TODAY=$(date +%Y-%m-%d)
if [ -f "$SESSION_DIR/$TODAY.md" ]; then
  echo "## Session Notes ($TODAY)"
  echo ""
  cat "$SESSION_DIR/$TODAY.md"
  echo ""
fi

# 4. Memory index
if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  echo "## Memory Index"
  echo ""
  cat "$MEMORY_DIR/MEMORY.md"
  echo ""
fi

# 5. Unanswered-Discord safety net
# Compact removes original "channel source=\"husky\"" user blocks, so enforce-discord-reply.sh
# can't see pre-compact unanswered messages. Remind explicitly here.
echo "## Unanswered Reply Check (CRITICAL)"
echo ""
echo "Compact replaces original Discord user blocks with summary text. The Stop hook only sees"
echo "post-compact Discord messages, so pre-compact 미답변 메시지를 놓친다."
echo ""
echo "Inspect the summary above. If a user 요청이 reply/dismiss tool 호출 없이 남아있다면:"
echo "  1. mcp__husky__reply 또는 mcp__husky__dismiss 로 지금 즉시 처리하라."
echo "  2. 이미 처리됐다고 확신하면 무시."
echo ""
echo "Default assumption: 미답변이 있다고 보고 summary 를 재검토할 것."
echo ""
echo "=== [PostCompact Recovery Complete] ==="
