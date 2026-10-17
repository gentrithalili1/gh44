---
name: gh44-implement
description: Build the approved plan, or a small ticket or task, slice by slice, then verify and review it.
argument-hint: "[Linear ticket | Sentry link | task] [--worktree [name]]"
disable-model-invocation: true
---

# Implement

Build what the approved `/gh44-plan` in this session describes. With no plan, build the ticket or task passed as the argument; when that is clearly more than one slice, suggest `/gh44-plan` first and wait.

Read-only on Linear and Sentry. Leave every change uncommitted: `/gh44-create-pr` commits and pushes.

## 1. Worktree (only with `--worktree`)

Name: the name passed, else the ticket ID (`ABC-123` from a Linear link, `sentry-<shortId>` from a Sentry link); with neither, ask for one. Run `git fetch origin`. `<base>` is the remote default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`). `<prepare>` is `"$(dirname "$(readlink ~/.claude/CLAUDE.md)")/hooks/prepare-worktree.sh"`. Take the first case that matches:

- **Already in a linked worktree** (`git rev-parse --git-dir` differs from `--git-common-dir`): if HEAD is detached, `git switch --no-track -c <name> <base>`. If dependencies are missing, run `<prepare> <this worktree> <main checkout>`. Stay here.
- **`git worktree list` has the branch `<name>`:** `EnterWorktree` with its path.
- **Otherwise:** `git worktree add --no-track <dir>/<name> -b <name> <base>`, where `<dir>` is what the repo's `CLAUDE.md`/`AGENTS.md` says, else `.worktrees`. `EnterWorktree` with that path, then run `<prepare> <path> <main checkout>` in the background; check it finished before running code.

Tell him the worktree path and branch in one line.

## 2. Build, slice by slice

Work the **frontier** of the plan: the next slice whose blockers have landed. A Sentry link without a plan is a bug: load `gh44-debug` first and build its fix as the slice.

For each slice:

1. Load `gh44-tdd` and run the red → green loop at the plan's seam.
2. Run typecheck and the slice's test file.
3. Tick its acceptance criteria and tell him in one line.

The plan is the contract. When it turns out wrong (a seam does not exist, a slice cannot land green), stop and ask before changing it. A hard bug inside a slice: load `gh44-debug`.

Done when every slice is green and every acceptance criterion is ticked.

## 3. Verify

Run the `gh44-verifier` agent. Fix every failure the change caused and run it again until it returns `PASS`.

## 4. Review

Run the `gh44-reviewer` agent on the local changes, with the plan's acceptance criteria. Apply the comments that have one clear fix, then run `gh44-verifier` again. Keep the judgement calls for him.

## 5. Report

```md
**Built:** <one line per slice>
**Checks:** verifier PASS · <n> review fixes applied
**Changed from the plan:** <each change and why, or "nothing">
**For you:** <judgement calls from the review, or "nothing">

Next: `/gh44-review-pr`, then `/gh44-create-pr`
```
