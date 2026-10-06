#!/usr/bin/env bash
# PostToolUse hook: runs the brain's ast-grep rules on the edited TS file.
# Only lines changed since HEAD are reported, so legacy code in the file is not flagged.
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v ast-grep > /dev/null && command -v jq > /dev/null || exit 0
file="$(jq -r '.tool_input.file_path // empty')"
case "$file" in *.ts | *.tsx | *.mts | *.cts) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0

dir="$(dirname "$file")"
changed="all"
if git -C "$dir" rev-parse --verify -q HEAD > /dev/null 2>&1 \
  && git -C "$dir" ls-files --error-unmatch -- "$file" > /dev/null 2>&1; then
  changed="$(git -C "$dir" diff -U0 HEAD -- "$file" \
    | awk '/^@@/ { split($3, range, ","); start = substr(range[1], 2); count = (range[2] == "" ? 1 : range[2]); for (i = 0; i < count; i++) print start + i }' \
    | jq -sc '.')"
fi

matches="$(ast-grep scan -c "$BRAIN/checks/sgconfig.yml" --json=compact "$file" 2> /dev/null || true)"
report="$(jq -r --arg changed "$changed" '
  ($changed | if . == "all" then null else fromjson end) as $lines
  | .[] | (.range.start.line + 1) as $line
  | select($lines == null or ($lines | index($line)))
  | "\(.file):\($line) \(.ruleId): \(.message)"' <<< "${matches:-[]}")"
[ -z "$report" ] && exit 0
{
  echo "agent-brain checks failed on lines you changed:"
  echo "$report"
} >&2
exit 2
