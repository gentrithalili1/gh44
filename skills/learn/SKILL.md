---
name: learn
description: Save how Gentrit works into ~/gh44. Use when he corrects you, states a preference or a rule, says "learn this" or "remember this", or runs /learn, /learn ingest or /learn tidy.
---

# Learn

The brain repo is `~/gh44`. Write files only there, except for route 1 below.

## Approval

1. Show the exact rule text, the file it goes to and why, in a few lines.
2. Wait for his answer: approve, edit or reject. For `/learn ingest`, show the whole batch at once and let him approve item by item.
3. After approval, write the files, run `for test in tests/*.test.sh; do bash "$test"; done` when lint or hooks changed, then commit and push in `~/gh44`.

Skip the approval only when he stated the rule plainly and you are very sure of its wording and place; then write, commit, push and report it in one line. Never commit in `~/gh44` without one of these two.

## Modes

- `/learn [lesson]` (capture): the lesson is the argument, or the latest correction in this session.
- `/learn ingest`: process each item (`hooks/capture-corrections.sh` adds raw prompts that look like corrections; drop the ones that are not lessons) below `<!-- items below -->` in `inbox.md`, then delete the processed items. Keep an item and report it when its link cannot be read. Read links with the right tool: Artifact `read` for claude.ai artifacts, WebFetch for other URLs.
- `/learn tidy`: review `CLAUDE.md`, every `rules/*.md` and every `skills/*/SKILL.md`. Merge duplicates, resolve contradictions, remove stale rules. If `CLAUDE.md` plus `rules/` is over 60 lines, move the most topic-specific rules into skills. List the rules that a script could check as hook candidates.

## Route each lesson (first match wins)

1. **Repository-specific** (true only because of one repo's setup: its tooling, folders, team, product or internal services, for example "use oxfmt, not prettier" in a repo that ships oxfmt): do not put it in the brain. Save it to the current project's auto-memory and say so. If it would hold in any repo he works in, it is not route 1. A repo-specific skill goes in that repo's skills folder, listed in `.git/info/exclude`; never in the brain. When a repo's convention conflicts with one of my lint rules, add the rule id to `rulesOff` in that repo's `.gh44.json`, also listed in `.git/info/exclude`.
2. **Script-checkable** (a command, file pattern or tool call that must always or never happen): propose the check in one line. A code rule becomes an ESLint rule in `lint/eslint.config.js`: an existing rule from ESLint or an installed plugin, otherwise a new `brain/` rule in `lint/rules/index.js`, with a test in `tests/lint.test.sh`. A command or tool-call pattern becomes a hook in `hooks/`, registered in `install.sh`. Write either only after he agrees. When a hook enforces a rule, keep the rule line and append `(enforced by hooks/<name>)`.
3. **Applies to some work only** (a language, framework, file type or task type): add it to the matching `skills/<topic>/SKILL.md`. If no skill matches, create `skills/<topic>/SKILL.md`. Its description must say when to load it. Add the skill to `## Topic skills` in `CLAUDE.md`, then run `~/gh44/install.sh` to link it.
4. **Applies to every session**: add it to the matching `rules/<topic>.md` (precedence, communication, workflow, code, learning), or create a new topic file. Keep `CLAUDE.md` to who I am and the skill list.

## Write the rule

- Write one imperative line, concrete. Add an example only when the rule is unclear without one.
- Search the target file first. If a rule overlaps, merge into it. If a rule contradicts, replace it and mention the old one.
- Keep `CLAUDE.md` plus `rules/` at 60 lines or fewer in total. If an addition would go over, move topic-specific rules into a skill.

## Record

Append one line to `log.md`:

`- YYYY-MM-DD | <file> | <added|merged|replaced|removed> | <rule> | <why, source>`

## Report

After writing, report one line per lesson with the commit, for example `Learned: rules/code.md +1 (a1b2c3d)`, and name every new file.
