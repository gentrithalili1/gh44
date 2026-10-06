#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
export TMPDIR="$(mktemp -d)"

repo="$(mktemp -d)"
git -C "$repo" init -q
printf 'export const a = 1\n' > "$repo/tracked.ts"
git -C "$repo" add tracked.ts
git -C "$repo" -c user.email=t@t -c user.name=t commit -q -m init

stop() {
  status=0
  output="$(jq -n --arg cwd "$repo" --argjson active "${2:-false}" '{session_id: $session, cwd: $cwd, stop_hook_active: $active}' --arg session "${1:-s1}" \
    | "$BRAIN/hooks/check-changed.sh" 2>&1)" || status=$?
}
start_turn() { jq -n --arg session "$1" '{session_id: $session, prompt: "x"}' | "$BRAIN/hooks/mark-turn.sh"; }

printf 'export const wip = value as Wip\n' > "$repo/wip.ts"
touch -t 202001010000 "$repo/wip.ts"

stop s1
[ "$status" -eq 0 ] || fail "no turn marker should pass: $output"

start_turn s1
touch -t 202001010100 "$TMPDIR/agent-brain-turn-s1"

stop s1
[ "$status" -eq 0 ] || fail "files changed before the turn are the user's: $output"

printf 'export const b = value as B\n' >> "$repo/tracked.ts"
printf 'export const c = value as C\n' > "$repo/new.tsx"
printf 'x as y\n' > "$repo/notes.md"
stop s1
[ "$status" -eq 2 ] || fail "changes in this turn should block (status $status)"
echo "$output" | grep -q "tracked.ts:2 no-as-cast" || fail "tracked change missing: $output"
echo "$output" | grep -q "new.tsx:1 no-as-cast" || fail "untracked change missing: $output"
echo "$output" | grep -q "wip.ts" && fail "reported the user's file: $output"

stop s1 true
[ "$status" -eq 0 ] || fail "second stop in a row must pass to avoid a loop"

stop other
[ "$status" -eq 0 ] || fail "another session's marker must not apply"

echo "PASS check-changed"
