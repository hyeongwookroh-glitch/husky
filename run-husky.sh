#!/bin/bash
# Husky — Claude Code session start script (auto-restart wrapper)
cd "$(dirname "$0")"
export MAGI_AGENT=husky

while true; do
  # Re-load .env on every spawn so restart tool also picks up env changes
  if [ -f .env ]; then
    set -a
    . ./.env
    set +a
  fi

  expect -c '
    set timeout -1
    spawn claude \
      --model opus \
      --effort xhigh \
      --dangerously-skip-permissions \
      --strict-mcp-config --mcp-config .mcp-husky.json \
      --dangerously-load-development-channels server:husky
    sleep 2
    send "\r"
    interact
  '
  EXIT_CODE=$?
  echo "[$(date)] Husky exited (code: $EXIT_CODE), restarting in 3s..."
  sleep 3
done
