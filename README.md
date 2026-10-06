# agent-brain

My personal Claude Code setup. It makes every Claude Code session, in any repository, work the way I work, and it learns from my corrections over time.

## How it loads

| Layer                | Loads                                                   | Holds                                                                                                                                                  |
| -------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `CLAUDE.md` + `rules/*.md` | Every session (linked to `~/.claude/CLAUDE.md` and `~/.claude/rules/`) | `CLAUDE.md`: who I am and the skill list. `rules/`: one short file per topic (precedence, communication, workflow, code, learning). Together 60 lines or fewer. |
| `skills/<topic>/`    | Only the description, until a task needs the full skill | Topic rules such as `code-structure`, and the `learn` skill                                                                                            |
| `hooks/`             | Never in context; the harness runs them                 | `check-code.sh` runs my ESLint rules on changed lines after each edit; `check-changed.sh` runs them at the end of each turn on every file changed in that turn (`mark-turn.sh` records the start); `capture-corrections.sh` fills `inbox.md`; `budget-check.sh` warns on core size and inbox count |
| `log.md`, `inbox.md` | Never                                                   | Learning history and raw input                                                                                                                         |

The repository's own `CLAUDE.md` or `AGENTS.md` wins on code conventions. This brain wins on how to work with me.

## Install

Needs Homebrew, Node and pnpm. `install.sh` installs `jq` with Homebrew when it is missing, and the lint packages with pnpm.

```bash
git clone git@github.com:gentrithalili1/agent-brain.git ~/agent-brain
~/agent-brain/install.sh
```

`install.sh` links `CLAUDE.md`, `rules/` and each skill into `~/.claude/`, and adds the brain's hooks to `~/.claude/settings.json`. It backs up `settings.json` first and keeps existing hooks. It never overwrites a real file; if something is in the way, it stops and changes nothing. You can run it again at any time.

Edits to the files here are live in the next session. Run `install.sh` again only after adding or removing a skill or a hook.

## Teaching it

- **In a session:** correct Claude, or say "learn this". The `learn` skill writes the rule into the right file.
- **Automatically:** prompts that look like corrections ("don't", "never", "I prefer", "no, ...") are captured into `inbox.md`.
- **In bulk:** paste raw rules, notes or links below the marker in `inbox.md`, then run `/learn ingest`.
- **Cleanup:** run `/learn tidy` to merge duplicates, remove stale rules and move rules into skills when `CLAUDE.md` plus `rules/` grows too big.

Each lesson goes to the cheapest layer that works:

1. Repository-specific lessons go to that repository: project memory, or a skill listed in `.git/info/exclude`. Never here.
2. Rules a script can check become a hook, after I agree to it.
3. Rules for some work only go into a topic skill.
4. Rules for every session go into `rules/<topic>.md`.

Every change is also recorded as one line in `log.md`. Review with `git status` and `git diff`, then commit.

## Lint rules (ESLint)

`lint/eslint.config.js` holds all my deterministic code rules. `hooks/check-code.sh` runs them on every TS file Claude edits, and `hooks/check-changed.sh` runs them again at the end of each turn on every file changed in that turn by any means, shell edits included:

- Fixable problems (import order, for example) are fixed in the file silently. Claude never sees them and no tokens are spent.
- Other errors on changed lines go back to Claude to fix.
- **The repository wins.** A rule is turned off when the repository configures it in its ESLint or oxlint config (including `extends`), or when one of its `equivalents` is configured. `formatter:sort-imports` means the repository's formatter (oxfmt, Prettier plugin, Biome) sorts imports.

A repository can also opt out of any of my rules with a `.agent-brain.json` file at its root, listed in `.git/info/exclude` so it stays local:

```json
{ "rulesOff": ["brain/component-props-name"] }
```

My own rules live in `lint/rules/index.js` under the `brain/` prefix: `brain/no-class-component`, `brain/component-props-name`, `brain/no-lint-disable` and `brain/pure-utils`. Write one there when no published ESLint rule covers the convention. Rules that apply to component files only go in `myComponentRules`.

To add a rule, add one line to `myRules`:

```js
const myRules = {
  // ...
  'no-nested-ternary': 'error',
}
```

To use a rule from a plugin, add the plugin with `pnpm add -D <plugin> --dir lint` and register it under `plugins` in the config. If the rule overlaps with rules that repositories commonly use under another name, list those names in `equivalents`.

Try a rule on real code: `node lint/run.mjs <file>`. Note that it fixes the file in place.

## Tests

```bash
for test in tests/*.test.sh; do bash "$test"; done
```

The tests use temporary home directories and never touch the real `~/.claude`.

## Docs

- Design: `docs/specs/2026-10-05-agent-brain-design.md`
- Implementation plan: `docs/plans/2026-10-05-agent-brain.md`
