#!/usr/bin/env bash
# Uninstalls GH44: removes its links, hooks and upstream skills from ~/.claude. With --remove-repo, also deletes
# this repository, but only when nothing would be lost. Safe to run again.
set -euo pipefail

BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
UPSTREAM="$BRAIN/upstream-skills.txt"
SKILL_LOCK="$HOME/.agents/.skill-lock.json"
REMOVE_REPO_FLAG="--remove-repo"
INBOX_MARKER="<!-- items below -->"
STEPS=4
changes=0

case "${1:-}" in
  "") remove_repo=false ;;
  "$REMOVE_REPO_FLAG") remove_repo=true ;;
  *)
    echo "usage: uninstall.sh [$REMOVE_REPO_FLAG]" >&2
    exit 1
    ;;
esac

if [ -t 1 ]; then
  bold=$'\033[1m' dim=$'\033[2m' green=$'\033[32m' red=$'\033[31m' reset=$'\033[0m'
else
  bold="" dim="" green="" red="" reset=""
fi
step() { printf '%s[%s/%s]%s %-8s ' "$dim" "$1" "$STEPS" "$reset" "$2"; }
ok() { printf '%s✓%s %s\n' "$green" "$reset" "$1"; }
failed() { printf '%s✗%s %s\n' "$red" "$reset" "$1"; }

printf '\n%sGH44%s %s· uninstall%s\n\n' "$bold" "$reset" "$dim" "$reset"

# Check the repository before touching anything, so a refusal never leaves a half uninstall.
if [ "$remove_repo" = true ]; then
  problems=()
  if git -C "$BRAIN" rev-parse --git-dir > /dev/null 2>&1; then
    [ -z "$(git -C "$BRAIN" status --porcelain)" ] || problems+=("uncommitted changes")
    if ! git -C "$BRAIN" rev-parse --abbrev-ref '@{upstream}' > /dev/null 2>&1; then
      problems+=("no upstream branch to compare with")
    elif [ -n "$(git -C "$BRAIN" log '@{upstream}..HEAD' --oneline)" ]; then
      problems+=("commits not pushed")
    fi
  fi
  # inbox.md is gitignored, so its items exist nowhere else.
  if [ -f "$BRAIN/inbox.md" ] && sed -n "/$INBOX_MARKER/,\$p" "$BRAIN/inbox.md" | tail -n +2 | grep -q '[^[:space:]]'; then
    problems+=("items left in inbox.md (run /gh44-learn ingest)")
  fi
  if [ "${#problems[@]}" -gt 0 ]; then
    printf 'uninstall: not removing %s: %s\n' "$BRAIN" "$(IFS=,; echo "${problems[*]}" | sed 's/,/, /g')" >&2
    exit 1
  fi
fi

step 1 Links
unlinked=0
for link in "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/rules" "$CLAUDE_DIR"/skills/* "$CLAUDE_DIR"/agents/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "$BRAIN/CLAUDE.md" | "$BRAIN/rules" | "$BRAIN"/skills/* | "$BRAIN"/agents/*) rm "$link" && unlinked=$((unlinked + 1)) ;;
  esac
done
changes=$((changes + unlinked))
ok "$unlinked removed"

step 2 Hooks
removed=0
if [ -f "$SETTINGS" ]; then
  commands=()
  for script in "$BRAIN"/hooks/*.sh; do
    commands+=("$(printf '%q' "$script")")
  done
  commands_json="$(printf '%s\n' "${commands[@]}" | jq -R . | jq -s .)"
  removed="$(jq --argjson ours "$commands_json" \
    '[.. | objects | select(.command? as $c | $c != null and ($ours | index($c)))] | length' "$SETTINGS")"
  if [ "$removed" -gt 0 ]; then
    cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
    updated="$(jq --argjson ours "$commands_json" '
      .hooks |= with_entries(
        .value |= (map(.hooks |= map(select((.command // "") as $c | $ours | index($c) | not)))
          | map(select(.hooks | length > 0))))
      | .hooks |= with_entries(select(.value | length > 0))
      | if .hooks == {} then del(.hooks) else . end' "$SETTINGS")"
    printf '%s\n' "$updated" > "$SETTINGS"
  fi
fi
changes=$((changes + removed))
ok "$removed removed"

step 3 Upstream
# Only skills the lock file records as installed from that repository, so a copy from elsewhere stays.
dropped=0
if [ -f "$UPSTREAM" ] && [ -f "$SKILL_LOCK" ]; then
  while read -r repo skill; do
    case "$repo" in "" | "#"*) continue ;; esac
    jq -e --arg skill "$skill" --arg repo "$repo" '.skills[$skill].source == $repo' "$SKILL_LOCK" > /dev/null || continue
    rm -rf "${CLAUDE_DIR:?}/skills/$skill"
    updated="$(jq --arg skill "$skill" 'del(.skills[$skill])' "$SKILL_LOCK")"
    printf '%s\n' "$updated" > "$SKILL_LOCK"
    dropped=$((dropped + 1))
  done < "$UPSTREAM"
fi
changes=$((changes + dropped))
ok "$dropped removed"

step 4 Repo
if [ "$remove_repo" = true ]; then
  rm -rf "$BRAIN"
  ok "deleted $BRAIN"
  changes=$((changes + 1))
else
  ok "kept $BRAIN (pass $REMOVE_REPO_FLAG to delete it)"
fi

if [ "$changes" -eq 0 ]; then
  printf '\n%sNothing to remove.%s\n\n' "$bold" "$reset"
else
  printf '\n%sDone.%s Open a new Claude Code session to drop it.\n\n' "$bold" "$reset"
fi
