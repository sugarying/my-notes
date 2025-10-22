#!/usr/bin/env bash
# Usage: ./scripts/new_note.sh "VAE" [tags]
TITLE="$1"
TAGS="${2:-diffusion}"
if [ -z "$TITLE" ]; then
  echo "Usage: $0 \"Title\" [tags]"
  exit 1
fi

DATE=$(date +%F)
SAFE_TITLE=$(echo "$TITLE" | tr ' ' '-' | tr -cd '[:alnum:]-')
OUT_DIR="notes"
mkdir -p "$OUT_DIR"

TEMPLATE="templates/daily_note.md"
OUT_FILE="$OUT_DIR/${DATE}-${SAFE_TITLE}.md"

if [ -f "$OUT_FILE" ]; then
  echo "Note already exists: $OUT_FILE"
  exit 1
fi

# portable replacement using perl (works on Windows Git Bash too)
perl -pe 'BEGIN{$/=undef} s/\{\{title\}\}/$ENV{"TITLE"}/ge; s/\{\{date\}\}/$ENV{"DATE"}/ge; s/\{\{tags\}\}/$ENV{"TAGS"}/ge' TITLE="$TITLE" DATE="$DATE" TAGS="$TAGS" "$TEMPLATE" > "$OUT_FILE"

echo "Created: $OUT_FILE"
