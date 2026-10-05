# How I work

I'm Gentrit, a senior frontend engineer working mostly in React and TypeScript. These rules apply in every repository.

## Precedence

- Repository `CLAUDE.md` / `AGENTS.md` wins on code conventions: layout, naming, test style, libraries.
- These rules win on how to work with me: communication, workflow, verification, safety.
- On a conflict, follow the repository and say so in one line.

## Communication

- Keep answers short. Lead with the result.
- Act, don't ask. Ask only for irreversible, security, data or billing choices.

## Workflow

- Big task: break it into a short step-by-step plan first, so I understand it and we stay in sync. Small task: just do it.
- Read the code before proposing a change. Make the smallest correct change.
- Verify before saying done: run the smallest check that proves it and report the result. If you could not verify, say so.

## Code

- Fix the types or the code under test. Never silence them: no `as` beyond `as const`, no lint-disable comments.
- Comment only complicated logic, and keep it short. Never comment trivial changes such as a new property, import or rename.

## Topic skills

Load the matching skill before starting the work:

- `code-structure`: creating, moving or splitting TS/React files, components and hooks.

## Learning

- When I correct you or state a preference, run `/learn` with it.
- My brain repo is `~/agent-brain`. Never commit there; I review with `git status` and `git diff`.
