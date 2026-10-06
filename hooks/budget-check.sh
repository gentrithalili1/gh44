#!/usr/bin/env bash
# SessionStart hook: tells Claude when the always-loaded core grew past its budget,
# or when the inbox holds enough captured items to sort.
file="${1:-$HOME/.claude/CLAUDE.md}"
inbox="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/inbox.md"
limit=60
inbox_limit=10

if [ -f "$file" ]; then
  lines="$(awk 'END { print NR }' "$file")"
  if [ "$lines" -gt "$limit" ]; then
    echo "agent-brain: core CLAUDE.md is $lines lines (budget $limit). Suggest /learn tidy to the user."
  fi
fi

if [ -f "$inbox" ]; then
  items="$(awk '/<!-- items below -->/ { below = 1; next } below && /^- / { count++ } END { print count + 0 }' "$inbox")"
  if [ "$items" -ge "$inbox_limit" ]; then
    echo "agent-brain: inbox has $items items. Suggest /learn ingest to the user."
  fi
fi
exit 0
