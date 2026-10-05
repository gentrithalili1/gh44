#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$BRAIN/hooks/budget-check.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"

seq 60 > "$tmp/ok.md"
[ -z "$("$HOOK" "$tmp/ok.md")" ] || fail "60 lines should be silent"

seq 61 > "$tmp/big.md"
"$HOOK" "$tmp/big.md" | grep -q "61 lines" || fail "61 lines should warn"

[ -z "$("$HOOK" "$tmp/missing.md")" ] || fail "missing file should be silent"

printf '%s\n' $(seq 60) > "$tmp/no-newline.md"; printf '61' >> "$tmp/no-newline.md"
"$HOOK" "$tmp/no-newline.md" | grep -q "61 lines" || fail "last line without newline should count"

echo "PASS budget-check"
