#!/bin/bash
# SessionStart hook: inject pickup.md whenever it exists.
# Fires on both source=="clear" (CLI /clear) and source=="startup" (headless claude -p).
# pickup.md is only written by /cp, so its presence is itself the consume signal.

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

if [ -f pickup.md ]; then
  echo "branch=$SOURCE+pickup cat+rm" >> "$LOG"
  echo '--- pickup.md context ---'
  cat pickup.md
  rm -f pickup.md .pickup-session-id
  echo '--- pickup.md has been read and deleted ---'
else
  echo "branch=$SOURCE+no-pickup" >> "$LOG"
fi
