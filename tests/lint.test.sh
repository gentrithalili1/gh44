#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$BRAIN/hooks/check-code.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }

run_hook() {
  status=0
  output="$(jq -n --arg file "$1" '{tool_name: "Edit", tool_input: {file_path: $file}}' | "$HOOK" 2>&1)" || status=$?
}
new_repo() {
  repo="$(mktemp -d)"
  git -C "$repo" init -q
}
unsorted() { printf "import { b } from './b'\nimport { a } from 'zod'\n\nexport const x = [a, b]\n" > "$1"; }

# No lint setup in the repo: my import order is fixed silently
new_repo
unsorted "$repo/sorted.ts"
run_hook "$repo/sorted.ts"
[ "$status" -eq 0 ] || fail "fixable problems must not block: $output"
[ "$(head -1 "$repo/sorted.ts")" = "import { a } from 'zod'" ] || fail "imports not sorted: $(cat "$repo/sorted.ts")"

# The repository's formatter sorts imports: mine stays off
new_repo
printf '{ "sortImports": { "order": "asc" } }\n' > "$repo/.oxfmtrc.json"
unsorted "$repo/owned.ts"
run_hook "$repo/owned.ts"
[ "$(head -1 "$repo/owned.ts")" = "import { b } from './b'" ] || fail "repo formatter owns import order"

# Non-fixable rule is reported
new_repo
printf 'export const f = (value: any) => value\n' > "$repo/any.ts"
run_hook "$repo/any.ts"
[ "$status" -eq 2 ] || fail "any should block (status $status)"
echo "$output" | grep -q "any.ts:1 @typescript-eslint/no-explicit-any" || fail "any not reported: $output"

# The repository configures the rule (oxlint, through extends): mine stays off
new_repo
mkdir -p "$repo/configs"
printf '{ "rules": { "typescript/no-explicit-any": "off" } }\n' > "$repo/configs/base.json"
printf '{ "extends": ["./configs/base.json"] }\n' > "$repo/.oxlintrc.json"
printf 'export const f = (value: any) => value\n' > "$repo/any.ts"
run_hook "$repo/any.ts"
[ "$status" -eq 0 ] || fail "repo oxlint config owns no-explicit-any: $output"

# Only changed lines are reported
new_repo
printf 'export const old = (value: any) => value\n' > "$repo/legacy.ts"
git -C "$repo" add legacy.ts
git -C "$repo" -c user.email=t@t -c user.name=t commit -q -m init
printf 'export const fresh = (value: any) => value\n' >> "$repo/legacy.ts"
run_hook "$repo/legacy.ts"
echo "$output" | grep -q "legacy.ts:2 " || fail "new any not reported: $output"
echo "$output" | grep -q "legacy.ts:1 " && fail "legacy line reported: $output"

# Inline disable comments for unknown repo rules do not break the run
new_repo
printf '// eslint-disable-next-line some-plugin/unknown-rule\nexport const y = 1\n' > "$repo/directive.ts"
run_hook "$repo/directive.ts"
echo "$output" | grep -qi "definition for rule" && fail "unknown rule directive broke lint: $output"

echo "PASS lint"
