---
name: gh44-learn
description: Save how Gentrit works into the brain repo. Use when he corrects you, states a preference or a rule, says "learn this" or "remember this", or runs /gh44-learn, /gh44-learn ingest, /gh44-learn tidy or /gh44-learn retro.
---

# Learn

The brain repo is the folder `~/.claude/CLAUDE.md` links to (`dirname "$(readlink ~/.claude/CLAUDE.md)"`). Write files only there, except for route 1 below.

## Approval

1. Ask with the question tool, one question per lesson: the exact rule text, the file it goes to and why, with options Approve and Reject (he edits through Other). Inbox items always go through this question. For `/gh44-learn ingest`, ask about the whole batch in as few rounds as possible.
2. Act on each answer: write the approved ones, apply his edits, drop the rejected.
3. After approval, write the files, run `for test in tests/*.test.sh; do bash "$test"; done` when lint or hooks changed, then commit and push in the brain repo.

Skip the approval only when he stated the rule plainly or said "learn this" in this session, and you are very sure of its wording and place; then write, commit, push and report it in one line. Never commit in the brain repo without one of these two.

## Modes

- `/gh44-learn [lesson]` (capture): the lesson is the argument, or the latest correction in this session. `hooks/capture-corrections.sh` also starts this mode by itself for short prompts that open with a correction keyword; after handling the lesson (learned or rejected), delete its line from `inbox.md`.
- `/gh44-learn ingest`: process each item (lessons the capture hook flagged but that were not handled in their session, plus anything pasted by hand; drop the ones that are not lessons) below `<!-- items below -->` in `inbox.md`, then delete the processed items. Keep an item and report it when its link cannot be read. Read links with the right tool: Artifact `read` for claude.ai artifacts, WebFetch for other URLs.
- `/gh44-learn tidy`: review `CLAUDE.md`, every `rules/*.md` and every `skills/*/SKILL.md`. Merge duplicates, resolve contradictions, remove stale rules. Rewrite each "never" rule as the behaviour to follow, keeping "never" only for a hard guardrail, paired with the positive target. If `CLAUDE.md` plus `rules/` is over 160 lines, move the most topic-specific rules into skills. List the rules that a script could check as hook candidates.
- `/gh44-learn retro [session]`: look back over this session, or the one he names (search the session logs on this machine), for friction he never corrected. Find candidates in these categories:
  - **Navigation**: a file or fact that took long to find → a pointer in the right `CLAUDE.md`/`AGENTS.md` or skill.
  - **Missed check**: a mistake lint, types or a test could have caught → route 2. Read the repo's own check scripts and CI first: an existing check that is unwired or broken is the finding.
  - **Missed review**: a mistake `gh44-code-review` should have flagged → a line in its checklist, or route 2 when it is mechanical.
  - **Tool economy**: an expensive or repeated tool call → a cheaper command, script or hook.
  - **Information access**: something Claude could not see (dev server logs, a service) → a way to reach it.
  - **No-op**: a rule or skill line that changed nothing this session → remove it.

  Route each through "Route each lesson" below. A gap in the team's repo (no CI lint, a missing pointer in its `AGENTS.md`) is a suggestion for the team: list it, never edit their files. Present all candidates most severe first, then ask as in Approval.

## Route each lesson (first match wins)

1. **Repository-specific** (true only because of one repo's setup: its tooling, folders, team, product or internal services, for example "use oxfmt, not prettier" in a repo that ships oxfmt): do not put it in the brain. Save it to the current project's auto-memory and say so. If it would hold in any repo he works in, it is not route 1. A repo-specific skill goes in that repo's skills folder, listed in `.git/info/exclude`; never in the brain. When a repo's convention conflicts with one of my lint rules, add the rule id to `rulesOff` in that repo's `.gh44.json`, also listed in `.git/info/exclude`.
2. **Script-checkable** (a command, file pattern or tool call that must always or never happen): propose the check in one line. A code rule becomes an ESLint rule in `lint/eslint.config.js`: first an existing rule from ESLint, `typescript-eslint`, `@eslint-react` or `eslint-plugin-testing-library` that works without type info, otherwise a new `brain/` rule in `lint/rules/index.js`; either way with a test in `tests/lint.test.sh`. A command or tool-call pattern becomes a hook in `hooks/`, registered in `install.sh`. Write either only after he agrees. When a hook enforces a rule, keep the rule line and append `(enforced by hooks/<name>)`.
3. **Applies to some work only** (a language, framework, file type or task type): add it to the matching `skills/gh44-<topic>/SKILL.md`. If no skill matches, create `skills/gh44-<topic>/SKILL.md` (every brain skill starts with `gh44-`). Its description must say when to load it. Add the skill to `## Topic skills` in `CLAUDE.md`, then run the brain repo's `install.sh` to link it.
4. **Applies to every session**: add it to the matching `rules/<topic>.md` (precedence, communication, workflow, code, learning), or create a new topic file. Keep `CLAUDE.md` to who I am and the skill list.

## Write the rule

- Write one imperative line, concrete. Add an example only when the rule is unclear without one.
- Search the target file first. If a rule overlaps, merge into it. If a rule contradicts, replace it and mention the old one.
- Search `log.md` too. If the same lesson was learned before, the text is not working: propose a route 2 check instead of rewording it.
- Keep `CLAUDE.md` plus `rules/` at 160 lines or fewer in total. If an addition would go over, move topic-specific rules into a skill.

## Record

Append one line to `log.md`:

`- YYYY-MM-DD | <file> | <added|merged|replaced|removed> | <rule> | <why, source>`

## Report

After writing, report one line per lesson with the commit, for example `Learned: rules/code.md +1 (a1b2c3d)`, and name every new file.
