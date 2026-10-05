# agent-brain

My personal Claude Code setup. It makes every Claude Code session, in any repository, work the way I work, and it learns from my corrections over time.

## How it loads

| Layer                | Loads                                                   | Holds                                                                               |
| -------------------- | ------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `CLAUDE.md`          | Every session (linked to `~/.claude/CLAUDE.md`)         | Core rules: communication, workflow, verification, code. Kept at 60 lines or fewer. |
| `skills/<topic>/`    | Only the description, until a task needs the full skill | Topic rules such as `code-structure`, and the `learn` skill                         |
| `hooks/`             | Never in context; the harness runs them                 | Rules a script can check. `budget-check.sh` warns when `CLAUDE.md` is over budget.  |
| `log.md`, `inbox.md` | Never                                                   | Learning history and raw input                                                      |

The repository's own `CLAUDE.md` or `AGENTS.md` wins on code conventions. This brain wins on how to work with me.

## Install

Requires `jq`.

```bash
git clone git@github.com:gentrithalili1/agent-brain.git ~/agent-brain
~/agent-brain/install.sh
```

`install.sh` links `CLAUDE.md` and each skill into `~/.claude/`, and adds the brain's hooks to `~/.claude/settings.json`. It backs up `settings.json` first and keeps existing hooks. It never overwrites a real file; if something is in the way, it stops and changes nothing. You can run it again at any time.

Edits to the files here are live in the next session. Run `install.sh` again only after adding or removing a skill or a hook.

## Teaching it

- **In a session:** correct Claude, or say "learn this". The `learn` skill writes the rule into the right file.
- **In bulk:** paste raw rules, notes or links below the marker in `inbox.md`, then run `/learn ingest`.
- **Cleanup:** run `/learn tidy` to merge duplicates, remove stale rules and move rules out of the core when it grows too big.

Each lesson goes to the cheapest layer that works:

1. Repository-specific lessons go to that repository: project memory, or a skill listed in `.git/info/exclude`. Never here.
2. Rules a script can check become a hook, after I agree to it.
3. Rules for some work only go into a topic skill.
4. Rules for every session go into `CLAUDE.md`.

Every change is also recorded as one line in `log.md`. Review with `git status` and `git diff`, then commit.

## Tests

```bash
bash tests/install.test.sh && bash tests/budget-check.test.sh
```

The tests use temporary home directories and never touch the real `~/.claude`.

## Docs

- Design: `docs/specs/2026-10-05-agent-brain-design.md`
- Implementation plan: `docs/plans/2026-10-05-agent-brain.md`
