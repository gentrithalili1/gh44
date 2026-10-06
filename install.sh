#!/usr/bin/env bash
# Links the brain into ~/.claude and registers its hooks. Safe to run again.
set -euo pipefail

BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

missing=()
for tool in jq ast-grep; do
  command -v "$tool" > /dev/null || missing+=("$tool")
done
if [ "${#missing[@]}" -gt 0 ]; then
  if ! command -v brew > /dev/null; then
    echo "install: missing ${missing[*]}. Install Homebrew (https://brew.sh) and run this again, or install them yourself." >&2
    exit 1
  fi
  echo "installing ${missing[*]} with Homebrew"
  brew install "${missing[@]}"
fi

if [ -f "$BRAIN/lint/package.json" ] && [ ! -d "$BRAIN/lint/node_modules" ]; then
  if command -v pnpm > /dev/null; then
    echo "installing lint packages"
    pnpm install --dir "$BRAIN/lint" --frozen-lockfile
  else
    echo "install: pnpm is missing, so ESLint checks are skipped (install Node and pnpm, then run this again)" >&2
  fi
fi

sources=("$BRAIN/CLAUDE.md")
targets=("$CLAUDE_DIR/CLAUDE.md")
for skill in "$BRAIN"/skills/*/; do
  [ -d "$skill" ] || continue
  skill="${skill%/}"
  sources+=("$skill")
  targets+=("$CLAUDE_DIR/skills/$(basename "$skill")")
done

# Check every target before linking anything, so a conflict never leaves a half install.
conflicts=0
for i in "${!targets[@]}"; do
  source="${sources[$i]}" target="${targets[$i]}"
  if [ -L "$target" ]; then
    [ "$(readlink "$target")" = "$source" ] && continue
    echo "install: $target links to $(readlink "$target"), expected $source" >&2
    conflicts=1
  elif [ -e "$target" ]; then
    echo "install: $target is a real file or folder; move it away first" >&2
    conflicts=1
  fi
done
[ "$conflicts" -eq 0 ] || exit 1

mkdir -p "$CLAUDE_DIR/skills"
for i in "${!targets[@]}"; do
  [ -L "${targets[$i]}" ] && continue
  ln -s "${sources[$i]}" "${targets[$i]}"
  echo "linked ${targets[$i]}"
done

for link in "$CLAUDE_DIR"/skills/*; do
  [ -L "$link" ] && [ ! -e "$link" ] || continue
  case "$(readlink "$link")" in
    "$BRAIN"/skills/*) rm "$link" && echo "removed stale link $link" ;;
  esac
done

add_hook() {
  local event="$1" script="$2" matcher="${3:-}" command updated
  command="$(printf '%q' "$BRAIN/hooks/$script")"
  if jq -e --arg command "$command" '[.. | objects | select(.command? == $command)] | length > 0' "$SETTINGS" > /dev/null; then
    return
  fi
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  # Drop this hook's entry from an earlier brain location before adding the current one.
  updated="$(jq --arg event "$event" --arg command "$command" --arg suffix "/hooks/$script" --arg matcher "$matcher" '
    .hooks[$event] = (
      ((.hooks[$event] // [])
        | map(.hooks |= map(select((.command // "") | endswith($suffix) | not)))
        | map(select(.hooks | length > 0)))
      + [(if $matcher == "" then {} else {matcher: $matcher} end) + {hooks: [{type: "command", command: $command}]}])' "$SETTINGS")"
  printf '%s\n' "$updated" > "$SETTINGS"
  echo "added $event hook: $command"
}

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
add_hook SessionStart budget-check.sh
add_hook UserPromptSubmit capture-corrections.sh
add_hook UserPromptSubmit mark-turn.sh
add_hook PostToolUse check-code.sh "Edit|Write|MultiEdit"
add_hook Stop check-changed.sh
