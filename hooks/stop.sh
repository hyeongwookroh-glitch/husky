#!/bin/bash
# Stop hook — mark session end in today's notes

HUSKY_MEMORY="${HUSKY_MEMORY_DIR:-$HOME/Documents/Husky_Memory}"
SESSION_DIR="$HUSKY_MEMORY/session_notes/husky"
TODAY=$(date +%Y-%m-%d)
SESSION_FILE="$SESSION_DIR/$TODAY.md"

if [ -f "$SESSION_FILE" ]; then
  echo "" >> "$SESSION_FILE"
  echo "---" >> "$SESSION_FILE"
  echo "_Session ended: $(date '+%H:%M')_" >> "$SESSION_FILE"
fi
