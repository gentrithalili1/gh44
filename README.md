# GH44

Gentrit's personal agent brain for Claude Code.

Every Claude Code session, in any repository, starts with my rules and works the way I do:

- **Rules** (`rules/`) tell Claude how I work: communication, workflow and code.
- **Skills** (`skills/`) load when the work needs them. See [How to use it](#how-to-use-it). Some are adapted from [Matt Pocock's skills](https://github.com/mattpocock/skills) (MIT, see `NOTICE`).
- **Lint checks** (`lint/`) run on every edit and fix or flag my code conventions, without using tokens.
- **Learning:** corrections are captured, and `/learn` turns them into rules after I approve.

The repository's own conventions always win over mine.

## How to use it

Every task goes through five steps. Small tasks can skip straight to execute; big ones use every step.

| Step | What you do | What runs |
| --- | --- | --- |
| 1. Clarify | Type `/grill-me` and describe the feature or ticket. Answer each round until nothing is left open. | `/grill-me` |
| 2. Plan | Ask for a plan, or switch to plan mode (`shift+tab`). Approve the step-by-step plan before any code is written. | `rules/workflow.md` |
| 3. Execute | Let Claude build it slice by slice, with tests first where it makes sense. | `tdd`, `code-structure`, `diagnosing-bugs`, lint hooks |
| 4. Review | Run `/gh44-review` on your branch, fix what matters, then `/code-review` for bugs and `/simplify` for cleanups. | `/gh44-review`, `/code-review`, `/simplify` |
| 5. Ship | Ask Claude to commit, push and open the PR. It does this only when you ask. | `gh` CLI |

Long session or switching context? Run `/handoff` and start a new session from the file it writes.

### Skills that load on their own

Claude picks these when the work matches. You can also type their names.

| Skill | Loads when |
| --- | --- |
| `code-structure` | Creating, moving or splitting TS/React files. A hook also adds it on the first TS edit of a session. |
| `tdd` | Building a feature or fixing a bug test-first. |
| `diagnosing-bugs` | A bug or slowdown without an obvious cause, or you say "debug this". |
| `writing-for-agents` | Editing skills, rules or a `CLAUDE.md`, including this repo. |
| `learn` | You correct Claude or state a preference. |

### Skills you type

| Command | Use it for |
| --- | --- |
| `/grill-me` | Before planning a feature: Claude asks rounds of questions, each with a recommended answer. |
| `/gh44-review [pr]` | Reviewing a PR, branch or local changes the way I review. Nothing is posted to GitHub unless you ask. |
| `/handoff [next focus]` | Writing the session down so a fresh session can continue it. |
| `/learn`, `/learn ingest`, `/learn tidy` | Saving a rule, sorting the inbox, cleaning up the rules. |

### Hooks (always on, no tokens)

- **Every TS edit:** ESLint runs with my rules and fixes or reports problems on changed lines.
- **End of each turn:** every TS file changed in that turn is checked again, however it was edited.
- **Every prompt:** messages that look like corrections are saved to `inbox.md` for `/learn ingest`.
- **Session start:** warns when the core rules go over 60 lines or the inbox fills up.

## Install

Needs Homebrew, Node and pnpm.

```bash
git clone git@github.com:gentrithalili1/gh44.git ~/gh44 && ~/gh44/install.sh
```

Then open a new Claude Code session.
