#!/usr/bin/env bash
# PostToolUse hook: checks the edited TS file with my ESLint rules (fixing what can be
# fixed) and my ast-grep rules. Only lines changed since HEAD are reported, so legacy
# code in the file is not flagged.
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v jq > /dev/null || exit 0
file="$(jq -r '.tool_input.file_path // empty')"
case "$file" in *.ts | *.tsx | *.mts | *.cts) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0

problems="[]"
if command -v node > /dev/null && [ -d "$BRAIN/lint/node_modules" ]; then
  eslint="$(node "$BRAIN/lint/run.mjs" "$file" 2> /dev/null || true)"
  problems="$(jq -c '.' <<< "${eslint:-[]}" 2> /dev/null || echo '[]')"
fi
if command -v ast-grep > /dev/null; then
  matches="$(ast-grep scan -c "$BRAIN/checks/sgconfig.yml" --json=compact "$file" 2> /dev/null || true)"
  problems="$(jq -c --argjson eslint "$problems" \
    '$eslint + map({line: (.range.start.line + 1), ruleId, message})' <<< "${matches:-[]}")"
fi

dir="$(dirname "$file")"
changed="all"
if git -C "$dir" rev-parse --verify -q HEAD > /dev/null 2>&1 \
  && git -C "$dir" ls-files --error-unmatch -- "$file" > /dev/null 2>&1; then
  changed="$(git -C "$dir" diff -U0 HEAD -- "$file" \
    | awk '/^@@/ { split($3, range, ","); start = substr(range[1], 2); count = (range[2] == "" ? 1 : range[2]); for (i = 0; i < count; i++) print start + i }' \
    | jq -sc '.')"
fi

report="$(jq -r --arg file "$file" --arg changed "$changed" '
  ($changed | if . == "all" then null else fromjson end) as $lines
  | .[] | .line as $line | select($lines == null or ($lines | index($line)))
  | "\($file):\(.line) \(.ruleId): \(.message)"' <<< "$problems")"
[ -z "$report" ] && exit 0
{
  echo "agent-brain checks failed on lines you changed:"
  echo "$report"
} >&2
exit 2
