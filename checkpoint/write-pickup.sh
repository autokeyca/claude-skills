#!/bin/bash
# write-pickup.sh — atomic write + verify for pickup.md and .pickup-session-id.
# Usage: write-pickup.sh < content.md   (reads pickup body from stdin)
# Writes to $(pwd)/pickup.md and $(pwd)/.pickup-session-id, verifies, prints a receipt.
# Exits non-zero if either file is missing or empty after the write.

set -euo pipefail

PROJECT_ROOT="$(pwd)"
PICKUP="$PROJECT_ROOT/pickup.md"
SENTINEL="$PROJECT_ROOT/.pickup-session-id"

PROJECT_HASH=$(echo "$PROJECT_ROOT" | tr '/' '-')
TRANSCRIPT_DIR="${CLAUDE_DATA_DIR:-$HOME/.claude}/projects/$PROJECT_HASH"
SID=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null | sed 's/\.jsonl$//' || true)

if [ -z "$SID" ]; then
  echo "FAIL: could not resolve session id from $TRANSCRIPT_DIR" >&2
  exit 2
fi

cat > "$PICKUP"
printf '%s\n' "$SID" > "$SENTINEL"

if [ ! -s "$PICKUP" ]; then
  echo "FAIL: pickup.md missing or empty at $PICKUP" >&2
  exit 3
fi
if [ ! -s "$SENTINEL" ]; then
  echo "FAIL: .pickup-session-id missing or empty at $SENTINEL" >&2
  exit 4
fi

BYTES=$(wc -c < "$PICKUP" | tr -d ' ')
LINES=$(wc -l < "$PICKUP" | tr -d ' ')
SHA=$(sha256sum "$PICKUP" | awk '{print substr($1,1,12)}')
SENTINEL_BYTES=$(wc -c < "$SENTINEL" | tr -d ' ')
STAMP=$(date -Iseconds)

echo "WROTE $PICKUP ${BYTES}B ${LINES}L sha=${SHA} sid=${SID} at=${STAMP}"
echo "WROTE $SENTINEL ${SENTINEL_BYTES}B sid=${SID}"
