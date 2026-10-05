#!/usr/bin/env bash
# SessionStart hook: tells Claude when the always-loaded core grew past its budget.
file="${1:-$HOME/.claude/CLAUDE.md}"
limit=60
[ -f "$file" ] || exit 0
lines="$(wc -l < "$file" | tr -d ' ')"
if [ "$lines" -gt "$limit" ]; then
  echo "agent-brain: core CLAUDE.md is $lines lines (budget $limit). Suggest /learn tidy to the user."
fi
exit 0
