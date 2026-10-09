#!/usr/bin/env bash
# Installs GH44: links it into ~/.claude and registers its hooks. Safe to run again.
set -euo pipefail

BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
STEPS=4
changes=0

if [ -t 1 ]; then
  bold=$'\033[1m' dim=$'\033[2m' green=$'\033[32m' red=$'\033[31m' reset=$'\033[0m'
else
  bold="" dim="" green="" red="" reset=""
fi
step() { printf '%s[%s/%s]%s %-7s ' "$dim" "$1" "$STEPS" "$reset" "$2"; }
ok() { printf '%s✓%s %s\n' "$green" "$reset" "$1"; }
failed() { printf '%s✗%s %s\n' "$red" "$reset" "$1"; }
changed() { [ "$1" -gt 0 ] && printf ' (%s changed)' "$1" || true; }

printf '\n%sGH44%s %s· Gentrit'"'"'s personal agent brain%s\n\n' "$bold" "$reset" "$dim" "$reset"

step 1 Tools
missing=()
for tool in jq; do
  command -v "$tool" > /dev/null || missing+=("$tool")
done
if [ "${#missing[@]}" -gt 0 ]; then
  if ! command -v brew > /dev/null; then
    failed "missing ${missing[*]}"
    echo "install: missing ${missing[*]}. Install Homebrew (https://brew.sh) and run this again, or install them yourself." >&2
    exit 1
  fi
  brew install "${missing[@]}" > /dev/null
  ok "installed ${missing[*]}"
  changes=$((changes + 1))
else
  ok "jq"
fi

step 2 Lint
if [ ! -f "$BRAIN/lint/package.json" ]; then
  ok "nothing to install"
elif [ -d "$BRAIN/lint/node_modules" ]; then
  ok "packages ready"
elif command -v pnpm > /dev/null; then
  pnpm install --dir "$BRAIN/lint" --frozen-lockfile > /dev/null
  ok "packages installed"
  changes=$((changes + 1))
else
  failed "skipped, pnpm is missing"
  echo "install: pnpm is missing, so ESLint checks are skipped (install Node and pnpm, then run this again)" >&2
fi

step 3 Links
sources=("$BRAIN/CLAUDE.md" "$BRAIN/rules")
targets=("$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/rules")
for skill in "$BRAIN"/skills/*/; do
  [ -d "$skill" ] || continue
  skill="${skill%/}"
  sources+=("$skill")
  targets+=("$CLAUDE_DIR/skills/$(basename "$skill")")
done

# Check every target before linking anything, so a conflict never leaves a half install.
# A link whose target no longer exists (the brain moved) is replaced.
conflicts=()
for i in "${!targets[@]}"; do
  source="${sources[$i]}" target="${targets[$i]}"
  if [ -L "$target" ]; then
    [ "$(readlink "$target")" = "$source" ] && continue
    [ -e "$target" ] || continue
    conflicts+=("install: $target links to $(readlink "$target"), expected $source")
  elif [ -e "$target" ]; then
    conflicts+=("install: $target is a real file or folder; move it away first")
  fi
done
if [ "${#conflicts[@]}" -gt 0 ]; then
  failed "${#conflicts[@]} in the way"
  printf '%s\n' "${conflicts[@]}" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR/skills"
linked=0
for i in "${!targets[@]}"; do
  target="${targets[$i]}"
  [ -L "$target" ] && [ "$(readlink "$target")" = "${sources[$i]}" ] && continue
  [ -L "$target" ] && rm "$target"
  ln -s "${sources[$i]}" "$target"
  linked=$((linked + 1))
done
for link in "$CLAUDE_DIR"/skills/*; do
  [ -L "$link" ] && [ ! -e "$link" ] || continue
  case "$(readlink "$link")" in
    "$BRAIN"/skills/*) rm "$link" && linked=$((linked + 1)) ;;
  esac
done
changes=$((changes + linked))
ok "CLAUDE.md, rules, $((${#targets[@]} - 2)) skills$(changed "$linked")"

step 4 Hooks
# inbox.md is gitignored, so a fresh clone needs one for capture-corrections to write to.
if [ ! -f "$BRAIN/inbox.md" ]; then
  printf '# Inbox\n\nPaste raw rules, notes and links below the marker. Run `/learn ingest` to sort them.\n\n<!-- items below -->\n' > "$BRAIN/inbox.md"
  changes=$((changes + 1))
fi
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
added=0
add_hook() {
  local event="$1" script="$2" matcher="${3:-}" command updated
  command="$(printf '%q' "$BRAIN/hooks/$script")"
  if jq -e --arg command "$command" '[.. | objects | select(.command? == $command)] | length > 0' "$SETTINGS" > /dev/null; then
    return
  fi
  [ "$added" -gt 0 ] || cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  # Drop this hook's entry from an earlier brain location before adding the current one.
  updated="$(jq --arg event "$event" --arg command "$command" --arg suffix "/hooks/$script" --arg matcher "$matcher" '
    .hooks[$event] = (
      ((.hooks[$event] // [])
        | map(.hooks |= map(select((.command // "") | endswith($suffix) | not)))
        | map(select(.hooks | length > 0)))
      + [(if $matcher == "" then {} else {matcher: $matcher} end) + {hooks: [{type: "command", command: $command}]}])' "$SETTINGS")"
  printf '%s\n' "$updated" > "$SETTINGS"
  added=$((added + 1))
}
add_hook SessionStart budget-check.sh
add_hook UserPromptSubmit capture-corrections.sh
add_hook UserPromptSubmit mark-turn.sh
add_hook UserPromptSubmit worktree-keyword.sh
add_hook PreToolUse load-structure.sh "Edit|Write|MultiEdit"
add_hook PostToolUse check-code.sh "Edit|Write|MultiEdit"
add_hook Stop check-changed.sh
changes=$((changes + added))
ok "7 hooks$(changed "$added")"

if [ "$changes" -eq 0 ]; then
  printf '\n%sUp to date.%s\n\n' "$bold" "$reset"
else
  printf '\n%sDone.%s Open a new Claude Code session to use it.\n\n' "$bold" "$reset"
fi
