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
jq -e --arg c "$BRAIN/hooks/capture-corrections.sh" \
  '[.hooks.UserPromptSubmit[].hooks[].command][0] == $c' "$HOME/.claude/settings.json" > /dev/null || fail "capture hook missing"
jq -e --arg c "$BRAIN/hooks/check-code.sh" \
  '.hooks.PostToolUse == [{matcher: "Edit|Write|MultiEdit", hooks: [{type: "command", command: $c}]}]' "$HOME/.claude/settings.json" > /dev/null \
  || fail "check-code hook wrong: $(jq -c '.hooks.PostToolUse' "$HOME/.claude/settings.json")"
jq -e --arg m "$BRAIN/hooks/mark-turn.sh" --arg s "$BRAIN/hooks/check-changed.sh" \
  '[.hooks.UserPromptSubmit[].hooks[].command][1] == $m and [.hooks.Stop[].hooks[].command] == [$s]' "$HOME/.claude/settings.json" > /dev/null \
  || fail "turn hooks missing: $(jq -c '.hooks' "$HOME/.claude/settings.json")"

# Second run changes nothing
[ -z "$("$BRAIN/install.sh")" ] || fail "second run was not a no-op"
jq -e '[.hooks.SessionStart, .hooks.UserPromptSubmit, .hooks.PostToolUse, .hooks.Stop | length] == [2, 2, 1, 1]' "$HOME/.claude/settings.json" > /dev/null || fail "hook duplicated"

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

# A conflict stops the run before anything is linked
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude/skills/learn"
"$BRAIN/install.sh" > /dev/null 2>&1 || true
[ ! -e "$HOME/.claude/CLAUDE.md" ] || fail "linked CLAUDE.md before failing on conflict"

# A link to another location is reported with its target
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude"
ln -s /old/brain/CLAUDE.md "$HOME/.claude/CLAUDE.md"
message="$("$BRAIN/install.sh" 2>&1 || true)"
echo "$message" | grep -q "/old/brain/CLAUDE.md" || fail "conflict message lacks link target"

# Brain path with a space, then moved: hook runs, and the old hook is replaced
export HOME="$(mktemp -d)"
spaced="$(mktemp -d)/my brain"
mkdir -p "$spaced" && cp -R "$BRAIN"/CLAUDE.md "$BRAIN"/install.sh "$BRAIN"/hooks "$BRAIN"/skills "$spaced"/
"$spaced/install.sh" > /dev/null
command="$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$HOME/.claude/settings.json")"
seq 61 > "$HOME/big.md"
bash -c "$command $HOME/big.md" | grep -q "61 lines" || fail "hook command breaks on a path with a space"
moved="$(mktemp -d)/moved"
mv "$spaced" "$moved"
rm "$HOME/.claude/CLAUDE.md" "$HOME/.claude/skills/learn" "$HOME/.claude/skills/code-structure"
"$moved/install.sh" > /dev/null
jq -e --arg c "$moved/hooks/budget-check.sh" '[.hooks.SessionStart[].hooks[].command] == [$c]' "$HOME/.claude/settings.json" > /dev/null \
  || fail "moved brain left a stale hook: $(jq -c '.hooks' "$HOME/.claude/settings.json")"

# Removed skills leave no dangling links
export HOME="$(mktemp -d)"
copy="$(mktemp -d)/brain"
mkdir -p "$copy" && cp -R "$BRAIN"/CLAUDE.md "$BRAIN"/install.sh "$BRAIN"/hooks "$BRAIN"/skills "$copy"/
"$copy/install.sh" > /dev/null
rm -rf "$copy/skills/code-structure"
"$copy/install.sh" > /dev/null
[ ! -L "$HOME/.claude/skills/code-structure" ] || fail "dangling skill link left behind"
ln -s /elsewhere/skill "$HOME/.claude/skills/foreign"
"$copy/install.sh" > /dev/null
[ -L "$HOME/.claude/skills/foreign" ] || fail "removed a link that is not ours"

# Missing tools are installed with Homebrew
export HOME="$(mktemp -d)"
fakebin="$(mktemp -d)"
for tool in readlink basename dirname; do ln -s "$(command -v "$tool")" "$fakebin/$tool"; done
cat > "$fakebin/brew" <<BREW
#!/bin/sh
echo "\$@" > "$fakebin/brew.log"
ln -s "$(command -v jq)" "$fakebin/jq"
BREW
chmod +x "$fakebin/brew"
PATH="$fakebin:/bin" "$BRAIN/install.sh" > /dev/null 2>&1 || fail "install with brew failed"
[ "$(cat "$fakebin/brew.log")" = "install jq" ] || fail "brew not asked for jq: $(cat "$fakebin/brew.log" 2>/dev/null)"

# Lint packages are installed with pnpm when missing
export HOME="$(mktemp -d)"
lintbrain="$(mktemp -d)/brain"
mkdir -p "$lintbrain/lint"
cp -R "$BRAIN"/CLAUDE.md "$BRAIN"/install.sh "$BRAIN"/hooks "$BRAIN"/skills "$lintbrain"/
cp "$BRAIN/lint/package.json" "$BRAIN/lint/pnpm-lock.yaml" "$lintbrain/lint/"
pnpmbin="$(mktemp -d)"
ln -s "$(command -v jq)" "$pnpmbin/jq"
printf '#!/bin/sh\necho "$@" > "%s/pnpm.log"\n' "$pnpmbin" > "$pnpmbin/pnpm"
chmod +x "$pnpmbin/pnpm"
PATH="$pnpmbin:/usr/bin:/bin" "$lintbrain/install.sh" > /dev/null 2>&1 || fail "install with lint failed"
grep -q "install --dir $lintbrain/lint --frozen-lockfile" "$pnpmbin/pnpm.log" || fail "pnpm not run: $(cat "$pnpmbin/pnpm.log" 2>/dev/null)"

# Without Homebrew, missing tools stop the install with a hint
export HOME="$(mktemp -d)"
nobrew="$(mktemp -d)"
for tool in readlink basename dirname; do ln -s "$(command -v "$tool")" "$nobrew/$tool"; done
message="$(PATH="$nobrew:/bin" "$BRAIN/install.sh" 2>&1)" && fail "should fail without brew"
echo "$message" | grep -q "missing jq" || fail "hint should name jq: $message"
[ ! -e "$HOME/.claude/CLAUDE.md" ] || fail "linked before tools were ready"

echo "PASS install"
