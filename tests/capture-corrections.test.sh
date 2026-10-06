#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

copy="$(mktemp -d)/brain"
mkdir -p "$copy/hooks"
cp "$BRAIN/hooks/capture-corrections.sh" "$copy/hooks/"
printf '# Inbox\n\n<!-- items below -->\n' > "$copy/inbox.md"
HOOK="$copy/hooks/capture-corrections.sh"

send() { jq -n --arg prompt "$1" --arg cwd "/work/frontend" '{prompt: $prompt, cwd: $cwd}' | "$HOOK"; }

[ -z "$(send "Don't add comments for new props")" ] || fail "hook must print nothing"
grep -q "| frontend | Don't add comments for new props" "$copy/inbox.md" || fail "correction not captured: $(cat "$copy/inbox.md")"

send "not like this, use a prop" > /dev/null
grep -q "not like this, use a prop" "$copy/inbox.md" || fail "'not like this' correction not captured"

send "I prefer early returns" > /dev/null
grep -q "I prefer early returns" "$copy/inbox.md" || fail "preference not captured"

before="$(wc -l < "$copy/inbox.md")"
send "fix the failing test in Button.test.tsx" > /dev/null
send "/learn never use npm" > /dev/null
send "cannot reproduce, notice the log" > /dev/null
send "no, use a prop instead of context" > /dev/null
send "do not explain too much, that was wrong" > /dev/null
send "<agent-message from=\"x\"> never do that </agent-message>" > /dev/null
send "<task-notification> <summary>don't stop</summary>" > /dev/null
[ "$(wc -l < "$copy/inbox.md")" -eq "$before" ] || fail "captured a non-correction: $(tail -3 "$copy/inbox.md")"

send "$(printf 'never do this\nsecond line')" > /dev/null
tail -1 "$copy/inbox.md" | grep -q "never do this second line" || fail "multi-line prompt not flattened"

send "never $(printf 'x%.0s' $(seq 600))" > /dev/null
[ "$(tail -1 "$copy/inbox.md" | wc -c)" -lt 400 ] || fail "long prompt not truncated"

rm "$copy/inbox.md"
send "never do that" > /dev/null || fail "missing inbox must not fail"
[ ! -e "$copy/inbox.md" ] || fail "missing inbox must not be created"

echo "PASS capture-corrections"
