#!/usr/bin/env bash
# UserPromptSubmit hook: appends prompts that look like corrections or preferences
# to inbox.md, so /learn ingest can turn them into rules. Prints nothing.
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INBOX="$BRAIN/inbox.md"
[ -f "$INBOX" ] && command -v jq > /dev/null || exit 0

input="$(cat)"
prompt="$(jq -r '.prompt // empty' <<< "$input" | tr '\n\r\t' '   ' | tr -s ' ')"
case "$prompt" in /* | "<"* | "") exit 0 ;; esac

pattern="(^|[^a-z'])(don'?t|never|always|stop|prefer|not like this)([^a-z]|$)"
grep -qiE "$pattern" <<< "$prompt" || exit 0

repo="$(basename "$(jq -r '.cwd // empty' <<< "$input")")"
printf -- '- %s | %s | %s\n' "$(date +%Y-%m-%d)" "${repo:-unknown}" "${prompt:0:300}" >> "$INBOX"
exit 0
