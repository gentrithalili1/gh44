---
name: gh44-ticket
description: Start work on a Linear ticket or a Sentry issue in its own worktree. Use when Gentrit runs /gh44-ticket, or pastes a Linear or Sentry link and asks to work on it.
argument-hint: "<Linear ID or link | Sentry link>"
---

# Ticket

Read-only on Linear and Sentry: never change status, assignee, labels or comments there.

## 1. Read the source

- **Linear** (an ID such as `ABC-123` or a linear.app link): `get_issue` with `gitBranchName`, `title`, `description`, `attachments`, `relations`, then `list_comments`. Open linked Figma frames, docs and parent issues only when the description depends on them.
- **Sentry** (a sentry.io link): `get_sentry_resource` with the URL. Keep the error, the in-app stack frames, the release and how often it happens. Run Seer only when the stack trace does not point to a cause.

Done when you can state the goal, the acceptance criteria and the parts of the code it touches.

## 2. Create the worktree

Run in the repo root, after `git fetch origin`:

- Name: the Linear identifier (`ABC-123`) or `sentry-<shortId>`. Branch: Linear's `gitBranchName`, or the name itself for Sentry.
- If `git worktree list` already has that branch, enter it with `EnterWorktree` `path` and say you are resuming.
- Otherwise `git worktree add <dir>/<name> -b <branch> origin/main`, where `<dir>` is what the repo's `CLAUDE.md`/`AGENTS.md` says, else `.claude/worktrees`. Then `EnterWorktree` with that `path`.
- Install dependencies once with the lockfile frozen.

Tell him in one line: the worktree path and branch.

## 3. Hand over to the work

- **Linear:** summarize the ticket in 3 lines, ask every open question in one round with the question tool, then follow the workflow rule: a short step-by-step plan he approves before any code.
- **Sentry:** load `gh44-debug` and start Phase 1 with the stack trace and frequency from step 1.

At the end, `/gh44-create-pr` takes the ticket ID from the branch name.
