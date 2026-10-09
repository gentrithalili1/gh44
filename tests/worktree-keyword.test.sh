#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$BRAIN/hooks/worktree-keyword.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }

send() { jq -n --arg prompt "$1" '{session_id: "s1", prompt: $prompt}' | "$HOOK"; }

out="$(send "worktree:THU-3432 fix the login redirect")"
jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"' <<< "$out" > /dev/null || fail "not a UserPromptSubmit output: $out"
grep -q 'EnterWorktree with name `THU-3432`' <<< "$(jq -r '.hookSpecificOutput.additionalContext' <<< "$out")" || fail "name missing: $out"
grep -q "origin/main" <<< "$out" || fail "base must be origin/main: $out"
grep -q "AGENTS.md says where worktrees go" <<< "$out" || fail "repo location rule missing: $out"

out="$(send "please start worktree:refactor/form.groups-v2")"
grep -q '`refactor/form.groups-v2`' <<< "$out" || fail "names with / . - should match: $out"

[ -z "$(send "fix the login redirect")" ] || fail "no keyword must stay silent"
[ -z "$(send "see myworktree:foo")" ] || fail "keyword inside a word must stay silent"
[ -z "$(send "worktree: foo")" ] || fail "empty name must stay silent"

echo "PASS worktree-keyword"
