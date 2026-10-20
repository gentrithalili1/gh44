---
name: gh44-implement
description: Build the approved plan, or a small ticket or task, slice by slice, then verify and review it.
argument-hint: "[Linear ticket | Sentry link | task] [--worktree [name]] [--here]"
disable-model-invocation: true
---

# Implement

Build what the approved `/gh44-plan` in this session describes. With no plan, build the ticket or task passed as the argument; when that is clearly more than one slice, suggest `/gh44-plan` first and wait.

With no plan, first write 2-4 acceptance criteria from the ticket or task, and ask its open questions with the question tool (up to 4; more: suggest `/gh44-clarify` and wait). Show the criteria in one block and build once he confirms; they go to the implementer and are the spec the reviewer checks in step 3.

Read-only on Linear and Sentry. Leave every change uncommitted: `/gh44-create-pr` commits and pushes.

## 1. Worktree (only with `--worktree`)

Name: the name passed, else the ticket ID (`ABC-123` from a Linear link, `sentry-<shortId>` from a Sentry link); with neither, ask for one. Run `git fetch origin`. `<base>` is the remote default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`). `<prepare>` is `"$(dirname "$(readlink ~/.claude/CLAUDE.md)")/hooks/prepare-worktree.sh"`. Take the first case that matches:

- **Already in a linked worktree** (`git rev-parse --git-dir` differs from `--git-common-dir`): if HEAD is detached, `git switch --no-track -c <name> <base>`. If dependencies are missing, run `<prepare> <this worktree> <main checkout>`. Stay here.
- **`git worktree list` has the branch `<name>`:** `EnterWorktree` with its path.
- **Otherwise:** `git worktree add --no-track <dir>/<name> -b <name> <base>`, where `<dir>` is what the repo's `CLAUDE.md`/`AGENTS.md` says, else `.worktrees`. `EnterWorktree` with that path, then run `<prepare> <path> <main checkout>` in the background; check it finished before running code.

Tell him the worktree path and branch in one line.

## 2. Build

A Sentry link without a plan is a bug: load `gh44-debug` first; its fix becomes the slice.

**In the background (default):** dispatch the `gh44-implementer` agent with the approved plan word for word, every decision from this conversation the plan does not hold, and the ticket ID. Tell him it is running and that you are free to talk. While it runs:

- Talk and plan with him; leave the code to the implementer.
- A change he agrees to: summarize it, and once he approves, send it to the implementer with SendMessage. If it already finished, SendMessage resumes it with the change.
- When it reports **blocked**, ask him, then send his answer the same way.

**With `--here`:** build in this session yourself, following the Build section of `~/.claude/agents/gh44-implementer.md`, and tell him each slice in one line as it lands. When the plan turns out wrong, stop and ask him.

Done when the implementer reports done, or every slice is green here.

## 3. Verify and review

Run two agents in parallel: `gh44-verifier`, and `gh44-reviewer` on the local changes with the plan's acceptance criteria. Then, in one round, fix every failure the change caused and apply the review comments that have one clear fix. Run `gh44-verifier` again until it returns `PASS`. Keep the judgement calls for him, numbered.

## 4. Report

```md
**Built:** <one line per slice>
**Checks:** verifier PASS · <n> review fixes applied
**Changed from the plan:** <each change and why, or "nothing">
**For you:** <numbered judgement calls from the review, or "nothing">

Next: `/gh44-create-pr`
```

When he picks judgement calls ("apply 1 and 3"), apply them and run `gh44-verifier` again.
