#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
isolated="$(mktemp -d)/brain"
mkdir -p "$isolated/hooks" && cp "$BRAIN/hooks/budget-check.sh" "$isolated/hooks/"
HOOK="$isolated/hooks/budget-check.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"

seq 60 > "$tmp/ok.md"
[ -z "$("$HOOK" "$tmp/ok.md" "$tmp/none")" ] || fail "60 lines should be silent"

seq 61 > "$tmp/big.md"
"$HOOK" "$tmp/big.md" "$tmp/none" | grep -q "61 lines" || fail "61 lines should warn"

[ -z "$("$HOOK" "$tmp/missing.md" "$tmp/none")" ] || fail "missing file should be silent"

printf '%s\n' $(seq 60) > "$tmp/no-newline.md"; printf '61' >> "$tmp/no-newline.md"
"$HOOK" "$tmp/no-newline.md" "$tmp/none" | grep -q "61 lines" || fail "last line without newline should count"

brain="$(mktemp -d)/brain"
mkdir -p "$brain/hooks" && cp "$HOOK" "$brain/hooks/"
printf '# Inbox\n\n<!-- items below -->\n' > "$brain/inbox.md"
for i in $(seq 9); do echo "- item $i" >> "$brain/inbox.md"; done
[ -z "$("$brain/hooks/budget-check.sh" "$tmp/ok.md" "$tmp/none")" ] || fail "9 inbox items should be silent"
echo "- item 10" >> "$brain/inbox.md"
"$brain/hooks/budget-check.sh" "$tmp/ok.md" "$tmp/none" | grep -q "10 items" || fail "10 inbox items should prompt /learn ingest"

# Rules count toward the always-loaded budget
core="$(mktemp -d)"
seq 30 > "$core/CLAUDE.md"
mkdir -p "$core/rules"
seq 20 > "$core/rules/a.md"
[ -z "$("$HOOK" "$core/CLAUDE.md" "$core/rules")" ] || fail "50 lines in total should be silent"
seq 11 > "$core/rules/b.md"
"$HOOK" "$core/CLAUDE.md" "$core/rules" | grep -q "61 lines" || fail "CLAUDE.md plus rules over 60 should warn"

echo "PASS budget-check"
