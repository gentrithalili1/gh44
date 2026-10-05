#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
cd /

# Existing settings with a plugin hook on the same event
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude"
echo '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"plugin.sh"}]}]}}' > "$HOME/.claude/settings.json"
"$BRAIN/install.sh" > /dev/null
[ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$BRAIN/CLAUDE.md" ] || fail "CLAUDE.md not linked"
[ "$(readlink "$HOME/.claude/skills/learn")" = "$BRAIN/skills/learn" ] || fail "learn not linked"
[ "$(readlink "$HOME/.claude/skills/code-structure")" = "$BRAIN/skills/code-structure" ] || fail "code-structure not linked"
jq -e --arg c "$BRAIN/hooks/budget-check.sh" \
  '[.hooks.SessionStart[].hooks[].command] == ["plugin.sh", $c]' "$HOME/.claude/settings.json" > /dev/null \
  || fail "hooks wrong: $(cat "$HOME/.claude/settings.json")"
ls "$HOME/.claude/" | grep -q 'settings.json.bak.' || fail "no backup"

# Second run changes nothing
[ -z "$("$BRAIN/install.sh")" ] || fail "second run was not a no-op"
jq -e '.hooks.SessionStart | length == 2' "$HOME/.claude/settings.json" > /dev/null || fail "hook duplicated"

# No settings.json yet
export HOME="$(mktemp -d)"
"$BRAIN/install.sh" > /dev/null
jq -e '.hooks.SessionStart | length == 1' "$HOME/.claude/settings.json" > /dev/null || fail "settings not created"

# Real files are never overwritten
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude/skills/learn"
if "$BRAIN/install.sh" > /dev/null 2>&1; then fail "should refuse real skill dir"; fi
[ -d "$HOME/.claude/skills/learn" ] && [ ! -L "$HOME/.claude/skills/learn" ] || fail "real skill dir changed"

export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude"
echo mine > "$HOME/.claude/CLAUDE.md"
if "$BRAIN/install.sh" > /dev/null 2>&1; then fail "should refuse real CLAUDE.md"; fi
[ "$(cat "$HOME/.claude/CLAUDE.md")" = mine ] || fail "real CLAUDE.md changed"

echo "PASS install"
