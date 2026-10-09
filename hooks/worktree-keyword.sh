#!/usr/bin/env bash
# UserPromptSubmit hook: when the prompt contains `worktree:<name>`, tells Claude to
# start the work in a new worktree with that name. Prints nothing otherwise.
command -v jq > /dev/null || exit 0

prompt="$(jq -r '.prompt // empty' 2> /dev/null)"
[[ "$prompt" =~ (^|[[:space:]])worktree:([A-Za-z0-9._/-]+) ]] || exit 0
name="${BASH_REMATCH[2]}"

jq -n --arg name "$name" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit",
  additionalContext: ("The prompt contains `worktree:" + $name + "`. Before anything else, fetch origin and call EnterWorktree with name `" + $name + "`, branched from the latest origin/main. Tell me in one line: the worktree path and branch. Then do the rest of my prompt inside it; if nothing else was asked, stop there.")}}'
exit 0
