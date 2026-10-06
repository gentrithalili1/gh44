# GH44

Gentrit's personal agent brain for Claude Code.

Every Claude Code session, in any repository, starts with my rules and works the way I do:

- **Rules** (`rules/`) tell Claude how I work: communication, workflow and code.
- **Skills** (`skills/`) load when the work needs them. See [How to use it](#how-to-use-it). Some are adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills) (MIT, see `NOTICE`).
- **Lint checks** (`lint/`) run on every edit and fix or flag my code conventions, without using tokens.
- **Learning:** corrections are captured, and `/gh44-learn` turns them into rules after I approve.

The repository's own conventions always win over mine.

## How to use it

Every task goes through five steps. Small tasks can skip straight to execute; big ones use every step.

| Step | What you do | What runs |
| --- | --- | --- |
| 1. Clarify | Type `/gh44-grill-me` and describe the feature or ticket. Answer each round until nothing is left open. | `/gh44-grill-me` |
| 2. Plan | Ask for a plan, or switch to plan mode (`shift+tab`). Approve the step-by-step plan before any code is written. | `rules/workflow.md` |
| 3. Execute | Let Claude build it slice by slice, with tests first where it makes sense. | `gh44-tdd`, `gh44-code-structure`, `gh44-diagnosing-bugs`, lint hooks |
| 4. Review | Run `/gh44-review` on your branch, fix what matters, then `/code-review` for bugs and `/simplify` for cleanups. | `/gh44-review`, `/code-review`, `/simplify` |
| 5. Ship | Run `/gh44-pr` (or ask to open the PR): it checks, commits, pushes and opens the PR with a summary visual, how to test and risk. | `/gh44-pr` |

Long session or switching context? Run `/gh44-handoff` and start a new session from the file it writes.

### Skills that load on their own

Claude picks these when the work matches. You can also type their names.

| Skill | Loads when |
| --- | --- |
| `gh44-code-structure` | Creating, moving or splitting TS/React files. A hook also adds it on the first TS edit of a session. |
| `gh44-tdd` | Building a feature or fixing a bug test-first. |
| `gh44-diagnosing-bugs` | A bug or slowdown without an obvious cause, or you say "debug this". |
| `gh44-writing-for-agents` | Editing skills, rules or a `CLAUDE.md`, including this repo. |
| `gh44-learn` | You correct Claude or state a preference. |
| `gh44-pr` | You ask to open or describe a PR. |

### Skills you type

| Command | Use it for |
| --- | --- |
| `/gh44-grill-me` | Before planning a feature: Claude asks rounds of questions, each with a recommended answer. |
| `/gh44-review [pr]` | Reviewing a PR, branch or local changes the way I review. Nothing is posted to GitHub unless you ask. |
| `/gh44-pr` | Shipping: commit, push, open the PR with a filled-in body. Uses the repo's PR template if it has one. |
| `/gh44-handoff [next focus]` | Writing the session down so a fresh session can continue it. |
| `/gh44-learn`, `/gh44-learn ingest`, `/gh44-learn tidy` | Saving a rule, sorting the inbox, cleaning up the rules. |

### Hooks (always on, no tokens)

- **Every TS edit:** ESLint runs with my rules and fixes or reports problems on changed lines.
- **End of each turn:** every TS file changed in that turn is checked again, however it was edited.
- **Every prompt:** messages that look like corrections are saved to `inbox.md` for `/gh44-learn ingest`.
- **Session start:** warns when the core rules go over 60 lines or the inbox fills up.

## Install

Needs Homebrew, Node and pnpm.

```bash
git clone git@github.com:gentrithalili1/gh44.git ~/gh44 && ~/gh44/install.sh
```

Then open a new Claude Code session.
