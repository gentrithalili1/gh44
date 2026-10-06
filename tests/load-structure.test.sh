#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$BRAIN/hooks/load-structure.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
export TMPDIR="$(mktemp -d)"

send() { jq -n --arg session "$1" --arg file "$2" '{session_id: $session, tool_name: "Edit", tool_input: {file_path: $file}}' | "$HOOK"; }

out="$(send s1 /repo/Card.tsx)"
jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' <<< "$out" > /dev/null || fail "not a PreToolUse output: $out"
context="$(jq -r '.hookSpecificOutput.additionalContext' <<< "$out")"
grep -q "## Placement: the importers decide" <<< "$context" || fail "structure guide missing"
grep -q "^name: gh44-code-structure" <<< "$context" && fail "frontmatter should be stripped"

[ -z "$(send s1 /repo/Other.ts)" ] || fail "second TS edit in the same session must stay silent"
[ -n "$(send s2 /repo/Other.ts)" ] || fail "a new session gets the guide again"
[ -z "$(send s3 /repo/README.md)" ] || fail "non-TS files are skipped"

echo "PASS load-structure"
