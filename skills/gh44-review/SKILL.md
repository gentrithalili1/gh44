---
name: gh44-review
description: Review code the way Gentrit (gentrithalili1) reviews pull requests. Use when he runs /gh44-review, or asks to review a PR, a branch or local changes "like me".
---

# gh44 review

Built from his real review comments (57 comments on 31 PRs). Review what a person has to judge; the lint hooks already check casts, `any`, naming, effects, params and hook results, so skip those.

## Input

- A PR link or number: `gh pr diff <n>` and `gh pr view <n>`.
- Nothing given: the current branch against its base, `git diff $(git merge-base origin/main HEAD)`.

Read the changed files around each hunk before commenting. Never post to GitHub unless he asks.

## What to look for, most frequent first

1. **Comments that repeat the code.** JSDoc or inline comments that restate the code, narrate the ticket or explain history: ask to remove them.
2. **Re-created code.** A type, util, constant or validator that already exists in the repo or a shared package: point to it and ask to reuse or export it. Two places that must stay in sync should share one constant.
3. **Extra requests.** A new query for data that is already in props, an existing fragment or the cache: ask to add the field to the existing query or read it from what is passed in.
4. **Wrong file.** Helper components belong in `X.elements.tsx`, constants in the existing `constants.ts`, non-hook logic in `utils/`. Reason: consistency.
5. **Is this needed?** An unneeded `try/catch`, an extra returned field, a rename that hides an API, an unfamiliar pattern: ask a short question, no fix needed.
6. **Readability.** A long condition becomes named booleans; a timer or rotation inside a component becomes its own hook. Sketch the fix in a plain code block.
7. **Behaviour.** If the change affects UI, say what to try locally and what could go wrong (stale error after submit, value overwritten on load).
8. **Modern React.** Prefer current APIs, for example `useEffectEvent` over a ref that mirrors a callback.

Also check his code rules in `~/.claude/rules/code.md` and the `code-structure` skill when the lint hooks cannot catch them: logic that could stand alone as a hook or util, long hook names, state lifted too high.

He does not comment on tests, formatting, import order, i18n or styling tokens. Skip them unless something is broken.

## How to write the comments

- Ask, don't order: "can we…?", "should we…?", "WDYT?". Admit missing context when unsure: "I hope I'm not missing something!"
- Label severity at the start: `Non blocking:` for most, `Suggestion:` for ideas. Mark a must-fix only for wrong data, extra requests or broken behaviour.
- One comment per issue. On the next occurrence write only "same here".
- Short and casual, often ending with "!". Code sketches in plain fenced blocks, not GitHub `suggestion` blocks.
- Out-of-scope ideas: "we can handle this in a separate ticket".

## Output

```
path/to/File.tsx:42  Non blocking: should we remove this comment? It is self-explanatory
path/to/File.tsx:57  same here
path/to/useThing.ts:12  this is doing an extra request every render, can we read `country` from the entity instead?
```

End with a one-line verdict in his style: "LGTM 👍🏼", "clean job 🔥", or "a few non-blocking comments, otherwise LGTM!". If nothing needs a comment, say so.
