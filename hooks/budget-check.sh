#!/usr/bin/env bash
# SessionStart hook: tells Claude when the always-loaded core (CLAUDE.md plus rules)
# grew past its budget, or when the inbox holds enough captured items to sort.
file="${1:-$HOME/.claude/CLAUDE.md}"
rules="${2:-$HOME/.claude/rules}"
inbox="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/inbox.md"
limit=60
inbox_limit=10

core=()
[ -f "$file" ] && core+=("$file")
for rule in "$rules"/*.md; do
  [ -f "$rule" ] && core+=("$rule")
done
if [ "${#core[@]}" -gt 0 ]; then
  lines="$(awk 'END { print NR }' "${core[@]}")"
  if [ "$lines" -gt "$limit" ]; then
    echo "gh44: core CLAUDE.md plus rules is $lines lines (budget $limit). Suggest /gh44-learn tidy to the user."
  fi
fi

if [ -f "$inbox" ]; then
  items="$(awk '/<!-- items below -->/ { below = 1; next } below && /^- / { count++ } END { print count + 0 }' "$inbox")"
  if [ "$items" -ge "$inbox_limit" ]; then
    echo "gh44: inbox has $items items. Suggest /gh44-learn ingest to the user."
  fi
fi
exit 0
