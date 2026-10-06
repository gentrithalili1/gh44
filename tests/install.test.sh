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
[ "$(readlink "$HOME/.claude/skills/gh44-learn")" = "$BRAIN/skills/gh44-learn" ] || fail "learn not linked"
[ "$(readlink "$HOME/.claude/rules")" = "$BRAIN/rules" ] || fail "rules not linked"
[ "$(readlink "$HOME/.claude/skills/gh44-code-structure")" = "$BRAIN/skills/gh44-code-structure" ] || fail "code-structure not linked"
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
"$BRAIN/install.sh" | grep -q "Up to date" || fail "second run was not a no-op"
jq -e '[.hooks.SessionStart, .hooks.UserPromptSubmit, .hooks.PreToolUse, .hooks.PostToolUse, .hooks.Stop | length] == [2, 2, 1, 1, 1]' "$HOME/.claude/settings.json" > /dev/null || fail "hook duplicated"

# No settings.json yet
export HOME="$(mktemp -d)"
"$BRAIN/install.sh" > /dev/null
jq -e '.hooks.SessionStart | length == 1' "$HOME/.claude/settings.json" > /dev/null || fail "settings not created"

# Real files are never overwritten
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude/skills/gh44-learn"
if "$BRAIN/install.sh" > /dev/null 2>&1; then fail "should refuse real skill dir"; fi
[ -d "$HOME/.claude/skills/gh44-learn" ] && [ ! -L "$HOME/.claude/skills/gh44-learn" ] || fail "real skill dir changed"

export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude"
echo mine > "$HOME/.claude/CLAUDE.md"
if "$BRAIN/install.sh" > /dev/null 2>&1; then fail "should refuse real CLAUDE.md"; fi
[ "$(cat "$HOME/.claude/CLAUDE.md")" = mine ] || fail "real CLAUDE.md changed"

# A conflict stops the run before anything is linked
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude/skills/gh44-learn"
"$BRAIN/install.sh" > /dev/null 2>&1 || true
[ ! -e "$HOME/.claude/CLAUDE.md" ] || fail "linked CLAUDE.md before failing on conflict"

# A link to another location is reported with its target
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude"
mkdir -p "$HOME/other" && touch "$HOME/other/CLAUDE.md"
ln -s "$HOME/other/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
message="$("$BRAIN/install.sh" 2>&1 || true)"
echo "$message" | grep -q "$HOME/other/CLAUDE.md" || fail "conflict message lacks link target"

# Links left by an old brain location that no longer exists are replaced
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude/skills"
ln -s /gone/brain/CLAUDE.md "$HOME/.claude/CLAUDE.md"
ln -s /gone/brain/skills/gh44-learn "$HOME/.claude/skills/gh44-learn"
"$BRAIN/install.sh" > /dev/null 2>&1 || fail "dangling links from an old location should be replaced"
[ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$BRAIN/CLAUDE.md" ] || fail "CLAUDE.md not relinked"
[ "$(readlink "$HOME/.claude/skills/gh44-learn")" = "$BRAIN/skills/gh44-learn" ] || fail "learn not relinked"

# Brain path with a space, then moved: hook runs, and the old hook is replaced
export HOME="$(mktemp -d)"
spaced="$(mktemp -d)/my brain"
mkdir -p "$spaced" && cp -R "$BRAIN"/CLAUDE.md "$BRAIN"/rules "$BRAIN"/install.sh "$BRAIN"/hooks "$BRAIN"/skills "$spaced"/
"$spaced/install.sh" > /dev/null
command="$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$HOME/.claude/settings.json")"
seq 61 > "$HOME/big.md"
bash -c "$command $HOME/big.md $HOME/no-rules" | grep -q "61 lines" || fail "hook command breaks on a path with a space"
moved="$(mktemp -d)/moved"
mv "$spaced" "$moved"
rm "$HOME/.claude/CLAUDE.md" "$HOME/.claude/rules" "$HOME/.claude/skills/"*
"$moved/install.sh" > /dev/null
jq -e --arg c "$moved/hooks/budget-check.sh" '[.hooks.SessionStart[].hooks[].command] == [$c]' "$HOME/.claude/settings.json" > /dev/null \
  || fail "moved brain left a stale hook: $(jq -c '.hooks' "$HOME/.claude/settings.json")"

# Removed skills leave no dangling links
export HOME="$(mktemp -d)"
copy="$(mktemp -d)/brain"
mkdir -p "$copy" && cp -R "$BRAIN"/CLAUDE.md "$BRAIN"/rules "$BRAIN"/install.sh "$BRAIN"/hooks "$BRAIN"/skills "$copy"/
"$copy/install.sh" > /dev/null
rm -rf "$copy/skills/gh44-code-structure"
"$copy/install.sh" > /dev/null
[ ! -L "$HOME/.claude/skills/gh44-code-structure" ] || fail "dangling skill link left behind"
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
cp -R "$BRAIN"/CLAUDE.md "$BRAIN"/rules "$BRAIN"/install.sh "$BRAIN"/hooks "$BRAIN"/skills "$lintbrain"/
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
