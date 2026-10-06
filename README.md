# GH44

Gentrit's personal agent brain for Claude Code.

Every Claude Code session, in any repository, starts with my rules and works the way I do:

- **Rules** (`rules/`) tell Claude how I work: communication, workflow and code.
- **Skills** (`skills/`) load when the work needs them: code structure, `/learn`, `/gh44-review`, and adapted versions of some [Matt Pocock skills](https://github.com/mattpocock/skills) (`tdd`, `diagnosing-bugs`, `writing-for-agents`, `/grill-me`, `/handoff`; MIT, see `NOTICE`).
- **Lint checks** (`lint/`) run on every edit and fix or flag my code conventions, without using tokens.
- **Learning:** corrections are captured, and `/learn` turns them into rules after I approve.

The repository's own conventions always win over mine.

## Install

Needs Homebrew, Node and pnpm.

```bash
git clone git@github.com:gentrithalili1/gh44.git ~/gh44 && ~/gh44/install.sh
```

Then open a new Claude Code session.
