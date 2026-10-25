#!/usr/bin/env bash
# Run by gh44-implementer before it reports done: reports my ESLint rules (check-code.sh
# --report) on the changed lines of every uncommitted TS file in the current repo. Prints
# nothing and exits 0 when clean; lists the problems and exits 1 otherwise.
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

root="$(git rev-parse --show-toplevel)"
report=""
while IFS= read -r path; do
  file="$root/$path"
  case "$file" in *.ts | *.tsx | *.mts | *.cts) ;; *) continue ;; esac
  [ -f "$file" ] || continue
  report+="$(jq -n --arg file "$file" '{tool_input: {file_path: $file}}' | "$BRAIN/hooks/check-code.sh" --report 2>&1 | grep -v '^gh44 checks failed' || true)"$'\n'
done < <({ git -C "$root" diff --name-only HEAD; git -C "$root" ls-files --others --exclude-standard; } | sort -u)

report="$(sed '/^$/d' <<< "$report")"
[ -z "$report" ] && exit 0
echo "gh44 checks failed on changed lines:"
echo "$report"
exit 1
