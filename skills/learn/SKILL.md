---
name: learn
description: Save how Gentrit works into ~/agent-brain. Use when he corrects you, states a preference or a rule, says "learn this" or "remember this", or runs /learn, /learn ingest or /learn tidy.
---

# Learn

The brain repo is `~/agent-brain`. Write files only there, except for route 1 below. Never commit, stage or push. He reviews with `git status` and `git diff`, so name every new file in the report.

## Modes

- `/learn [lesson]` (capture): the lesson is the argument, or the latest correction in this session.
- `/learn ingest`: process each item (`hooks/capture-corrections.sh` adds raw prompts that look like corrections; drop the ones that are not lessons) below `<!-- items below -->` in `inbox.md`, then delete the processed items. Keep an item and report it when its link cannot be read. Read links with the right tool: Artifact `read` for claude.ai artifacts, WebFetch for other URLs.
- `/learn tidy`: review `CLAUDE.md` and every `skills/*/SKILL.md`. Merge duplicates, resolve contradictions, remove stale rules. If `CLAUDE.md` is over 60 lines, move the most topic-specific rules into skills. List the rules that a script could check as hook candidates.

## Route each lesson (first match wins)

1. **Repository-specific** (true only because of one repo's setup: its tooling, folders, team, product or internal services, for example "use oxfmt, not prettier" in a repo that ships oxfmt): do not put it in the brain. Save it to the current project's auto-memory and say so. If it would hold in any repo he works in, it is not route 1. A repo-specific skill goes in that repo's skills folder, listed in `.git/info/exclude`; never in the brain. When a repo's convention conflicts with one of my lint or ast-grep rules, add the rule id to `rulesOff` in that repo's `.agent-brain.json`, also listed in `.git/info/exclude`.
2. **Script-checkable** (a command, file pattern or tool call that must always or never happen): propose the check in one line. A code rule becomes an ESLint rule in `myRules` of `lint/eslint.config.js` when ESLint or an installed plugin has one, otherwise an ast-grep rule in `checks/rules/`. `hooks/check-code.sh` runs both on changed lines after each edit. A command or tool-call pattern becomes a hook in `hooks/`, registered in `install.sh`. Write either only after he agrees. When a hook enforces a rule, keep the rule line and append `(enforced by hooks/<name>)`.
3. **Applies to some work only** (a language, framework, file type or task type): add it to the matching `skills/<topic>/SKILL.md`. If no skill matches, create `skills/<topic>/SKILL.md`. Its description must say when to load it. Add the skill to `## Topic skills` in `CLAUDE.md`, then run `~/agent-brain/install.sh` to link it.
4. **Applies to every session**: add it to `CLAUDE.md` under the heading that fits.

## Write the rule

- Write one imperative line, concrete. Add an example only when the rule is unclear without one.
- Search the target file first. If a rule overlaps, merge into it. If a rule contradicts, replace it and mention the old one.
- Keep `CLAUDE.md` at 60 lines or fewer. If an addition would go over, move topic-specific rules into a skill.

## Record

Append one line to `log.md`:

`- YYYY-MM-DD | <file> | <added|merged|replaced|removed> | <rule> | <why, source>`

## Report

Report one line per lesson, for example `Learned: skills/code-structure +1`. Nothing else.
