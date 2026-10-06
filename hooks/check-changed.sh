#!/usr/bin/env bash
# Stop hook: runs check-code.sh on every TS file changed during this turn, however it
# was edited (Edit tool, shell, script). Blocks the stop once so Claude can react.
# Staged files and bulk changes come from git operations (merge, checkout), not from
# Claude, so only unstaged and untracked files count, and more than 30 skips the check.
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

input="$(cat)"
[ "$(jq -r '.stop_hook_active // false' <<< "$input")" = "true" ] && exit 0
session="$(jq -r '.session_id // empty' <<< "$input" | tr -cd 'A-Za-z0-9_-')"
marker="${TMPDIR:-/tmp}/agent-brain-turn-$session"
cwd="$(jq -r '.cwd // empty' <<< "$input")"
[ -n "$session" ] && [ -f "$marker" ] && [ -d "$cwd" ] || exit 0
root="$(git -C "$cwd" rev-parse --show-toplevel 2> /dev/null)" || exit 0

files=()
while IFS= read -r path; do
  file="$root/$path"
  case "$file" in *.ts | *.tsx | *.mts | *.cts) ;; *) continue ;; esac
  [ -f "$file" ] && [ "$file" -nt "$marker" ] && files+=("$file")
done < <({ git -C "$root" diff --name-only; git -C "$root" ls-files --others --exclude-standard; } | sort -u)
[ "${#files[@]}" -gt 0 ] && [ "${#files[@]}" -le 30 ] || exit 0

report=""
for file in "${files[@]}"; do
  report+="$(jq -n --arg file "$file" '{tool_input: {file_path: $file}}' | "$BRAIN/hooks/check-code.sh" 2>&1 | grep -v '^agent-brain checks failed' || true)"$'\n'
done

report="$(sed '/^$/d' <<< "$report")"
[ -z "$report" ] && exit 0
{
  echo "agent-brain checks failed on files changed this turn. Fix them, or tell the user why you kept them:"
  echo "$report"
} >&2
exit 2
