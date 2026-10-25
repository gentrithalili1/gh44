#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

repo="$(mktemp -d)"
git -C "$repo" init -q
printf 'export const a = value as A\n' > "$repo/legacy.ts"
git -C "$repo" add legacy.ts
git -C "$repo" -c user.email=t@t -c user.name=t commit -q -m init

run() { status=0; output="$(cd "$repo" && "$BRAIN/hooks/report-changed.sh" 2>&1)" || status=$?; }

run
[ "$status" -eq 0 ] && [ -z "$output" ] || fail "clean repo should pass silently: $output"

printf 'export const b = value as B\n' >> "$repo/legacy.ts"
printf 'export const c = value as C\n' > "$repo/new.tsx"
printf 'x as y\n' > "$repo/notes.md"
run
[ "$status" -eq 1 ] || fail "changes with problems should fail (status $status)"
echo "$output" | grep -q "legacy.ts:2 @typescript-eslint/consistent-type-assertions" || fail "tracked change missing: $output"
echo "$output" | grep -q "new.tsx:1 @typescript-eslint/consistent-type-assertions" || fail "untracked file missing: $output"
echo "$output" | grep -q "legacy.ts:1 " && fail "reported a legacy line: $output"
echo "$output" | grep -q "notes.md" && fail "reported a non-TS file: $output"

echo "PASS report-changed"
