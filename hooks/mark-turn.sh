#!/usr/bin/env bash
# UserPromptSubmit hook: records when the turn started, so check-changed.sh only
# looks at files changed during this turn. Prints nothing.
session="$(jq -r '.session_id // empty' 2> /dev/null | tr -cd 'A-Za-z0-9_-')"
[ -n "$session" ] && touch "${TMPDIR:-/tmp}/gh44-turn-$session"
exit 0
