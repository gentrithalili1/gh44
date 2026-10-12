#!/usr/bin/env bash
# UserPromptSubmit hook: appends prompts that look like corrections or preferences
# to inbox.md, so /gh44-learn ingest can turn them into rules. Prints nothing.
# Long prompts and pasted documents are task briefs from scripts and agents, not corrections.
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INBOX="$BRAIN/inbox.md"
[ -f "$INBOX" ] && command -v jq > /dev/null || exit 0

input="$(cat)"
prompt="$(jq -r '.prompt // empty' <<< "$input" | tr '\n\r\t' '   ' | tr -s ' ')"
case "$prompt" in /* | "<"* | "#"* | "") exit 0 ;; esac
[ "${#prompt}" -le 400 ] || exit 0

pattern="(^|[^a-z'])(don'?t|never|always|stop|prefer|not like this)([^a-z]|$)"
grep -qiE "$pattern" <<< "$prompt" || exit 0

repo="$(basename "$(jq -r '.cwd // empty' <<< "$input")")"
printf -- '- %s | %s | %s\n' "$(date +%Y-%m-%d)" "${repo:-unknown}" "${prompt:0:300}" >> "$INBOX"
exit 0
