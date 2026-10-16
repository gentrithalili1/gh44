#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
cd /
# npx stands in for the skills CLI, so no test reaches the network.
stubbin="$(mktemp -d)"
ln -s "$BRAIN/tests/fake-npx" "$stubbin/npx"
export PATH="$stubbin:$PATH"

copy_brain() {
  local dir
  dir="$(mktemp -d)/brain"
  mkdir -p "$dir"
  cp -R "$BRAIN"/CLAUDE.md "$BRAIN"/rules "$BRAIN"/install.sh "$BRAIN"/uninstall.sh "$BRAIN"/hooks "$BRAIN"/skills "$BRAIN"/agents "$dir"/
  echo "$dir"
}

# Removes our links and hooks, keeps everything else
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude/skills"
echo '{"model":"opus","hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"plugin.sh"}]}]}}' > "$HOME/.claude/settings.json"
"$BRAIN/install.sh" > /dev/null
ln -s /elsewhere/skill "$HOME/.claude/skills/foreign"
"$BRAIN/uninstall.sh" > /dev/null
[ ! -e "$HOME/.claude/CLAUDE.md" ] || fail "CLAUDE.md link left"
[ ! -e "$HOME/.claude/rules" ] || fail "rules link left"
[ ! -L "$HOME/.claude/skills/gh44-learn" ] || fail "skill link left"
[ ! -L "$HOME/.claude/agents/gh44-reviewer.md" ] || fail "agent link left"
[ -L "$HOME/.claude/skills/foreign" ] || fail "removed a link that is not ours"
[ ! -e "$HOME/.claude/skills/grilling" ] && [ ! -e "$HOME/.claude/skills/handoff" ] || fail "upstream skill left"
jq -e '.skills == {}' "$HOME/.agents/.skill-lock.json" > /dev/null || fail "lock entries left: $(cat "$HOME/.agents/.skill-lock.json")"
jq -e '. == {"model":"opus","hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"plugin.sh"}]}]}}' "$HOME/.claude/settings.json" > /dev/null \
  || fail "settings wrong: $(cat "$HOME/.claude/settings.json")"
[ -d "$BRAIN" ] || fail "repo deleted without the flag"

# Second run changes nothing
"$BRAIN/uninstall.sh" | grep -q "Nothing to remove" || fail "second run was not a no-op"

# Real files are never removed
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude"
echo mine > "$HOME/.claude/CLAUDE.md"
"$BRAIN/uninstall.sh" > /dev/null
[ "$(cat "$HOME/.claude/CLAUDE.md")" = mine ] || fail "real CLAUDE.md removed"

# An upstream-named skill installed from another repository stays
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude/skills/grilling" "$HOME/.agents"
echo '{"version":3,"skills":{"grilling":{"source":"someone/else"}}}' > "$HOME/.agents/.skill-lock.json"
"$BRAIN/uninstall.sh" > /dev/null
[ -d "$HOME/.claude/skills/grilling" ] || fail "removed a skill from another repository"

# Unknown argument stops the run
"$BRAIN/uninstall.sh" --nope > /dev/null 2>&1 && fail "should reject unknown argument"

# --remove-repo deletes a copy that is not a git repo and has an empty inbox
export HOME="$(mktemp -d)"
copy="$(copy_brain)"
"$copy/install.sh" > /dev/null
"$copy/uninstall.sh" --remove-repo > /dev/null || fail "remove-repo failed"
[ ! -e "$copy" ] || fail "repo not deleted"
[ ! -e "$HOME/.claude/CLAUDE.md" ] || fail "links left after remove-repo"

# --remove-repo refuses when inbox items would be lost, before touching anything
export HOME="$(mktemp -d)"
copy="$(copy_brain)"
"$copy/install.sh" > /dev/null
echo "- a rule I never ingested" >> "$copy/inbox.md"
message="$("$copy/uninstall.sh" --remove-repo 2>&1)" && fail "should refuse with inbox items"
echo "$message" | grep -q "inbox.md" || fail "message should name the inbox: $message"
[ -d "$copy" ] || fail "repo deleted despite inbox items"
[ -L "$HOME/.claude/CLAUDE.md" ] || fail "unlinked before refusing"

# --remove-repo refuses with uncommitted changes
export HOME="$(mktemp -d)"
copy="$(copy_brain)"
git -C "$copy" init -q && git -C "$copy" add -A && git -C "$copy" -c user.name=t -c user.email=t@t commit -qm init
touch "$copy/new-file"
message="$("$copy/uninstall.sh" --remove-repo 2>&1)" && fail "should refuse with uncommitted changes"
echo "$message" | grep -q "uncommitted" || fail "message should name uncommitted changes: $message"
[ -d "$copy" ] || fail "repo deleted despite uncommitted changes"

echo "PASS uninstall"
