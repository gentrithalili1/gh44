#!/usr/bin/env bash
# Links the brain into ~/.claude and registers its hooks. Safe to run again.
set -euo pipefail

BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v jq > /dev/null || { echo "install: jq is required (brew install jq)" >&2; exit 1; }

link() {
  local source="$1" target="$2"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "install: $target exists and is not a link to $source; move it away first" >&2
    exit 1
  fi
  ln -s "$source" "$target"
  echo "linked $target"
}

add_hook() {
  local event="$1" command="$2" updated
  if jq -e --arg command "$command" '[.. | objects | select(.command? == $command)] | length > 0' "$SETTINGS" > /dev/null; then
    return
  fi
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  updated="$(jq --arg event "$event" --arg command "$command" \
    '.hooks[$event] = ((.hooks[$event] // []) + [{hooks: [{type: "command", command: $command}]}])' "$SETTINGS")"
  printf '%s\n' "$updated" > "$SETTINGS"
  echo "added $event hook: $command"
}

mkdir -p "$CLAUDE_DIR/skills"
link "$BRAIN/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
for skill in "$BRAIN"/skills/*/; do
  [ -d "$skill" ] || continue
  skill="${skill%/}"
  link "$skill" "$CLAUDE_DIR/skills/$(basename "$skill")"
done

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
add_hook SessionStart "$BRAIN/hooks/budget-check.sh"
