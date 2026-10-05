# Agent brain: design

Date: 2026-10-05
Status: draft, waiting for review

## Goal

Every Claude Code session, in any repository, starts out working the way Gentrit works. The setup learns from corrections over time, while the context that is always loaded stays small.

Success means:

- A new session follows the core rules without being reminded.
- A correction given once does not need to be given again.
- All rules are plain files in one private git repository, and each change shows up in `git diff`.
- The always-loaded part stays under its budget, even as the number of rules grows.

Out of scope: Codex and other agents, a knowledge wiki, team-shared rules, and Join-specific facts. Join-specific facts stay in per-project auto-memory.

## Repository

`~/agent-brain`, a private repository at github.com/gentrithalili1/agent-brain.

```
agent-brain/
  CLAUDE.md            core rules, always loaded
  skills/
    learn/SKILL.md     capture, ingest and tidy lessons
    code-structure/    topic rules, loaded on demand
    <topic>/           more topic rules over time
  hooks/
    budget-check.sh    SessionStart: warn when CLAUDE.md is over budget
  inbox.md             raw rules dump, emptied by /learn ingest
  log.md               append-only history of lessons, never loaded
  install.sh           symlinks into ~/.claude and merges hooks into settings.json
  docs/specs/          design documents
```

`install.sh` creates these links:

- `~/.claude/CLAUDE.md` links to `agent-brain/CLAUDE.md`.
- `~/.claude/skills/<name>` links to `agent-brain/skills/<name>`, one link per skill. Skills that already exist in `~/.claude/skills` stay where they are.

`install.sh` adds only the brain's hooks to `~/.claude/settings.json`, using `jq`. It leaves the existing plugin hooks unchanged and backs up the file first. Running it a second time changes nothing.

## Loading layers

| Layer                | When it loads                                   | Cost                         | Contents                                                          |
| -------------------- | ----------------------------------------------- | ---------------------------- | ----------------------------------------------------------------- |
| `CLAUDE.md`          | Every session                                   | Max 60 lines                 | Principles, communication, workflow, precedence rule, skill index |
| Topic skills         | Name and description always; body when relevant | About 1 line each until used | Code structure, testing style, other topic rules                  |
| Hooks                | Never in context                                | Zero                         | Rules that a script can check                                     |
| `log.md`, `inbox.md` | Never                                           | Zero                         | History and raw input                                             |

Path-scoped `~/.claude/rules/*.md` was considered and rejected. The `paths:` frontmatter in user-level rules is reported as ignored (claude-code issues #21858 and #87217), so those rules would load in every session. Skills give the on-demand loading this design needs, because only the description stays in context. A skill's description must say when to load it, for example: "Use when creating, moving or splitting TypeScript or React files."

## Precedence

The project's `CLAUDE.md` and `AGENTS.md` load after the user file and take priority. The brain states the split explicitly:

- The repository wins on code conventions: layout, naming, test style, libraries.
- The brain wins on how to work with Gentrit: communication, workflow, verification and safety.

The brain therefore avoids rules that a repository usually defines. When a topic skill conflicts with the repository's rules, Claude follows the repository and says so in one line.

## Initial core content

The core starts with these rules:

- Keep answers short.
- Act, don't ask. Ask only for irreversible, security, data or billing choices.
- Big task: break it into a short step-by-step plan first, so I understand it and we stay in sync. Small task: just do it.
- Verify before saying something is done: run the smallest check that proves it, and report the result.
- Fix types or the code under test. Never silence a rule with `as` casts or lint-disable comments.
- Write comments only for complicated logic, and keep them short. Never comment trivial changes such as a new property.
- When the user corrects you, run `/learn`.

The first topic skill is `code-structure`, compressed from the "Frontend Structure Rules" artifact. It covers unit folder shape, placement by importers, top-down state, file kinds, when to split, and separating move-only from behavior changes.

## Learning loop

`/learn` has three modes.

1. **capture** (default): turn one correction from the current session into a rule.
2. **ingest**: process every item in `inbox.md`, then empty it.
3. **tidy**: find duplicates, contradictions and stale rules; move rules out of the core when it is over budget; propose hooks.

For each lesson, `/learn` does the following:

1. Choose where the lesson goes, in this order:
   1. A hook, if a script can check it.
   2. A topic skill, if it applies only to some kinds of work.
   3. The core, if it applies to every session.
   4. Drop it, if it is repository-specific or a duplicate. A repository-specific lesson goes to that project's auto-memory instead.
2. Merge with an existing rule when they overlap. Write the result as one imperative line.
3. Write the files in `~/agent-brain` without committing.
4. Append one line to `log.md`: date, target file, the rule, and the reason.
5. Report it in one line, for example "Learned: skills/code-structure +1".

A rule that is replaced by a hook is deleted from the text files.

Gentrit reviews with `git diff`, then commits or reverts. Claude never commits in this repository.

## Budget

`hooks/budget-check.sh` runs at SessionStart. It counts the lines in `~/.claude/CLAUDE.md`. If the count is over 60, it prints a short notice that tells Claude to suggest `/learn tidy`. It never blocks the session.

## Error handling

- `install.sh` stops if `jq` is missing, or if a real file (not a symlink) already exists at a link target. It never overwrites user files.
- `install.sh` makes a timestamped backup of `settings.json` before writing to it.
- `/learn` never writes outside `~/agent-brain`, except to the current project's auto-memory for repository-specific lessons.

## Verification

- Run `install.sh` twice. The second run reports no changes, and `settings.json` keeps all of its earlier hooks.
- Start a new session in a different repository. Ask "what are my rules?". The answer lists the core rules.
- Ask for a task that creates a TS file. The `code-structure` skill loads.
- Run `budget-check.sh` against a test file with 61 lines. The notice appears.
- Put one item in `inbox.md` and run `/learn ingest`. The rule lands in the right file, `log.md` gets one line, and the inbox is empty.

## Open items

- Later, mine `~/.claude/history.jsonl` for repeated corrections and ingest them.
- If skills do not load reliably on their descriptions, add a PreToolUse hook that injects a topic file when Claude touches files that match its paths.
