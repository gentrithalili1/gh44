---
name: gh44-ticket
description: Start work on a Linear ticket or a Sentry issue in its own worktree. Use when Gentrit runs /gh44-ticket, or pastes a Linear or Sentry link and asks to work on it.
argument-hint: "<Linear ID or link | Sentry link>"
---

# Ticket

Read-only on Linear and Sentry: never change status, assignee, labels or comments there.

## 1. Read the source

- **Linear** (an ID such as `ABC-123` or a linear.app link): `get_issue` with `title`, `description`, `attachments`, `relations`, then `list_comments`. Open linked Figma frames, docs and parent issues only when the description depends on them.
- **Sentry** (a sentry.io link): `get_sentry_resource` with the URL. Keep the error, the in-app stack frames, the release and how often it happens. Run Seer only when the stack trace does not point to a cause.

Done when you can state the goal, the acceptance criteria and the parts of the code it touches.

## 2. Create the worktree

Run in the repo root, after `git fetch origin`:

- Name: the ticket ID, used for both the worktree folder and the branch: the Linear identifier (`THU-3662` from `linear.app/.../issue/THU-3662/...`) or `sentry-<shortId>`.
- If `git worktree list` already has that branch, enter it with `EnterWorktree` `path` and say you are resuming.
- Otherwise `git worktree add <dir>/<name> -b <name> origin/main`, where `<dir>` is what the repo's `CLAUDE.md`/`AGENTS.md` says, else `.claude/worktrees`. Then `EnterWorktree` with that `path`.
- Make it ready to run: copy every gitignored `.env*` file from the main checkout to the same path in the worktree (from `git ls-files --others --ignored --exclude-standard`, skipping `node_modules` and worktree folders), then install dependencies with the lockfile frozen in the background while you go on to step 3. Done when the install has finished and the env files are in place, so he can start the app there anytime.

Tell him in one line: the worktree path and branch.

## 3. Hand over to the work

- **Linear:** summarize the ticket in 3 lines, ask every open question in one round with the question tool, then follow the workflow rule: a short step-by-step plan he approves before any code.
- **Sentry:** load `gh44-debug` and start Phase 1 with the stack trace and frequency from step 1.

At the end, `/gh44-create-pr` takes the ticket ID from the branch name.
