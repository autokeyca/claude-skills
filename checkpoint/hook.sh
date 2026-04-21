#!/bin/bash
# SessionStart hook: inject pickup.md only on source=="clear" (post-/clear).
# Headless claude -p sessions fire source=="startup" and are safely ignored.

set -u
PAYLOAD=$(cat)
SOURCE=$(echo "$PAYLOAD" | jq -r '.source // empty' 2>/dev/null)
SESSION_ID=$(echo "$PAYLOAD" | jq -r '.session_id // empty' 2>/dev/null)

LOG=/tmp/cp-hook.log
{
  echo "=== $(date -Iseconds) ==="
  echo "cwd=$(pwd)"
  echo "source=$SOURCE"
  echo "session_id=$SESSION_ID"
  echo "pickup_exists=$([ -f pickup.md ] && echo YES || echo NO)"
  echo "sentinel_exists=$([ -f .pickup-session-id ] && echo YES || echo NO)"
  [ -f .pickup-session-id ] && echo "saved_sid=$(cat .pickup-session-id)"
} >> "$LOG" 2>&1

if [ "$SOURCE" != "clear" ]; then
  echo "branch=source-not-clear ($SOURCE) skip" >> "$LOG"
  exit 0
fi

if [ -f pickup.md ]; then
  echo "branch=clear+pickup cat+rm" >> "$LOG"
  echo '--- pickup.md context ---'
  cat pickup.md
  rm -f pickup.md .pickup-session-id
  echo '--- pickup.md has been read and deleted ---'
else
  echo "branch=clear+no-pickup" >> "$LOG"
fi
