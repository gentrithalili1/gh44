#!/usr/bin/env bash
# PreToolUse hook: the first time Claude edits a TS file in a session, adds the
# code-structure guide to its context, so the guide does not depend on Claude loading it.
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$BRAIN/skills/gh44-code-structure/SKILL.md"
command -v jq > /dev/null && [ -f "$SKILL" ] || exit 0

input="$(cat)"
case "$(jq -r '.tool_input.file_path // empty' <<< "$input")" in *.ts | *.tsx | *.mts | *.cts) ;; *) exit 0 ;; esac
session="$(jq -r '.session_id // empty' <<< "$input" | tr -cd 'A-Za-z0-9_-')"
marker="${TMPDIR:-/tmp}/gh44-structure-$session"
[ -n "$session" ] && [ ! -f "$marker" ] || exit 0
touch "$marker"

guide="$(awk 'NR == 1 && /^---$/ { front = 1; next } front && /^---$/ { front = 0; next } !front' "$SKILL")"
jq -n --arg guide "$guide" '{hookSpecificOutput: {hookEventName: "PreToolUse",
  additionalContext: ("Follow my code-structure guide for this and every later TS edit:\n\n" + $guide)}}'
exit 0
