#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$BRAIN/hooks/check-code.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }

run_hook() {
  status=0
  output="$(jq -n --arg file "$1" '{tool_name: "Edit", tool_input: {file_path: $file}}' | "$HOOK" 2>&1)" || status=$?
}

repo="$(mktemp -d)"
git -C "$repo" init -q
git -C "$repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
printf 'const legacy = value as Legacy\n' > "$repo/old.ts"
git -C "$repo" add old.ts
git -C "$repo" -c user.email=t@t -c user.name=t commit -q -m old

run_hook "$repo/old.ts"
[ "$status" -eq 0 ] || fail "existing violations on untouched lines must be ignored: $output"

printf 'const fresh = value as Fresh\n' >> "$repo/old.ts"
run_hook "$repo/old.ts"
[ "$status" -eq 2 ] || fail "new cast should block (status $status)"
echo "$output" | grep -q "old.ts:2" || fail "should point at the new line: $output"
echo "$output" | grep -q "old.ts:1" && fail "should not report the old line: $output"

printf 'export const sizes = [1, 2] as const\n' > "$repo/new.ts"
run_hook "$repo/new.ts"
[ "$status" -eq 0 ] || fail "as const is allowed: $output"

printf '// eslint-disable-next-line\nexport const x = 1\n' > "$repo/lint.tsx"
run_hook "$repo/lint.tsx"
[ "$status" -eq 2 ] || fail "lint-disable in a new file should block"

mkdir -p "$repo/utils"
printf "import { useState } from 'react'\n" > "$repo/utils/format.ts"
run_hook "$repo/utils/format.ts"
[ "$status" -eq 2 ] || fail "react import in utils/ should block"

printf "import { render } from 'react'\n" > "$repo/utils/format.test.ts"
run_hook "$repo/utils/format.test.ts"
[ "$status" -eq 0 ] || fail "tests in utils/ may import react: $output"

printf 'x = y as Z\n' > "$repo/notes.md"
run_hook "$repo/notes.md"
[ "$status" -eq 0 ] || fail "non-TS files are skipped"

outside="$(mktemp -d)/loose.ts"
printf 'const a = b as C\n' > "$outside"
run_hook "$outside"
[ "$status" -eq 2 ] || fail "files outside git are checked in full"

run_hook "$repo/missing.ts"
[ "$status" -eq 0 ] || fail "missing file is skipped"

echo "PASS check-code"
