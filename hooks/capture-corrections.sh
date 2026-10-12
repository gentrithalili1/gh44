#!/usr/bin/env bash
# UserPromptSubmit hook: when a short prompt opens with a correction keyword, tells Claude
# to learn it now and appends it to inbox.md as a fallback for /gh44-learn ingest.
# Corrections are short and lead with the keyword; anything else is a task, not a lesson.
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INBOX="$BRAIN/inbox.md"
max_length=100
[ -f "$INBOX" ] && command -v jq > /dev/null || exit 0

input="$(cat)"
prompt="$(jq -r '.prompt // empty' <<< "$input" | tr '\n\r\t' '   ' | tr -s ' ' | sed 's/^ *//; s/ *$//')"
[ -n "$prompt" ] && [ "${#prompt}" -le "$max_length" ] || exit 0

pattern="^(no,? )?(i prefer|don'?t|never|always|stop|prefer|not like this)([^a-z]|$)"
grep -qiE "$pattern" <<< "$prompt" || exit 0

repo="$(basename "$(jq -r '.cwd // empty' <<< "$input")")"
item="- $(date +%Y-%m-%d) | ${repo:-unknown} | $prompt"
printf '%s\n' "$item" >> "$INBOX"

jq -n --arg item "$item" --arg inbox "$INBOX" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit",
  additionalContext: ("This prompt reads like a correction. First do what it asks. Then, if it is a lasting rule and not just about this task, apply the gh44-learn skill to it (capture mode). Either way, delete this line from " + $inbox + ": " + $item)}}'
exit 0
