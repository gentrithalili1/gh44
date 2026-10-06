# GH44

Gentrit's personal agent brain for Claude Code.

Every Claude Code session, in any repository, starts with my rules and works the way I do:

- **Rules** (`rules/`) tell Claude how I work: communication, workflow and code.
- **Skills** (`skills/`) load when the work needs them: code structure, `/learn` and `/gh44-review`.
- **Lint checks** (`lint/`) run on every edit and fix or flag my code conventions, without using tokens.
- **Learning:** corrections are captured, and `/learn` turns them into rules after I approve.

The repository's own conventions always win over mine.

## Install

Needs Homebrew, Node and pnpm.

```bash
git clone git@github.com:gentrithalili1/gh44.git ~/gh44 && ~/gh44/install.sh
```

Then open a new Claude Code session.
