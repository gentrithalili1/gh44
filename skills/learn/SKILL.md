---
name: learn
description: Save how Gentrit works into ~/agent-brain. Use when he corrects you, states a preference or a rule, says "learn this" or "remember this", or runs /learn, /learn ingest or /learn tidy.
---

# Learn

The brain repo is `~/agent-brain`. Write files there. Never commit, stage or push. He reviews with `git status` and `git diff`, so name every new file in the report.

## Modes

- `/learn [lesson]` (capture): the lesson is the argument, or the latest correction in this session.
- `/learn ingest`: process each item below `<!-- items below -->` in `inbox.md`, then delete the processed items. Read links with the right tool: Artifact `read` for claude.ai artifacts, WebFetch for other URLs.
- `/learn tidy`: review `CLAUDE.md` and every `skills/*/SKILL.md`. Merge duplicates, resolve contradictions, remove stale rules. If `CLAUDE.md` is over 60 lines, move the most topic-specific rules into skills. List the rules that a script could check as hook candidates.

## Route each lesson (first match wins)

1. **Repository-specific** (names a repo, product, team or internal tool): do not put it in the brain. Save it to the current project's auto-memory and say so.
2. **Script-checkable** (a command, file pattern or tool call that must always or never happen): propose a hook in one line, naming the event, the matcher and the check. Write it to `hooks/` and register it in `install.sh` only after he agrees. When a hook enforces a rule, keep the rule line and append `(enforced by hooks/<name>)`.
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
