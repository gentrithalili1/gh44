---
name: gh44-review-pr
description: Review code the way Gentrit (gentrithalili1) reviews pull requests. Use when he runs /gh44-review-pr, or asks to review a PR, a branch or local changes "like me".
---

# gh44 review

Built from his real review comments (57 comments on 31 PRs). Review what a person has to judge; the lint hooks already check casts, `any`, naming, effects, params, hook results, nested JSX ternaries, index keys and `&&` renders, so skip those.

## Input

- A PR link or number: `gh pr diff <n>` and `gh pr view <n>`.
- Nothing given: the current branch against its base, `git diff $(git merge-base origin/main HEAD)`.

Read the changed files around each hunk before commenting. Post to GitHub only through the pending review below.

## Run in a fresh context

Unless you are the `gh44-reviewer` agent, dispatch it with the input and wait for its review. Show its output to him unchanged, then do the Pending review step yourself.

## What to look for, most frequent first

1. **Comments that repeat the code.** JSDoc or inline comments that restate the code, narrate the ticket or explain history: ask to remove them.
2. **Re-created code.** A type, util, constant or validator that already exists in the repo or a shared package: point to it and ask to reuse or export it. Two places that must stay in sync should share one constant.
3. **Extra requests.** A new query for data that is already in props, an existing fragment or the cache: ask to add the field to the existing query or read it from what is passed in.
4. **Wrong file.** Code that doesn't follow the repo's file layout (its `AGENTS.md`/`CLAUDE.md` and sibling folders) or, where the repo is silent, my `~/.claude/rules/structure.md`: helper JSX, constants or non-hook logic in the wrong file. Reason: consistency.
5. **Is this needed?** An unneeded `try/catch`, an extra returned field, a rename that hides an API, an unfamiliar pattern: ask a short question, no fix needed.
6. **Readability.** A long condition becomes named booleans; a timer or rotation inside a component becomes its own hook. Sketch the fix in a plain code block.
7. **Behaviour.** If the change affects UI, say what to try locally and what could go wrong (stale error after submit, value overwritten on load).
8. **Modern React.** Prefer current APIs, for example `useEffectEvent` over a ref that mirrors a callback.

Also check his rules in `~/.claude/rules/code.md` and `~/.claude/rules/structure.md` when the lint hooks cannot catch them: logic that could stand alone as a hook or util, long hook names, state lifted too high, boolean piles instead of a status union, non-exhaustive `switch`, boolean props instead of a `variant`, wrong element for the job (`div` with `onClick`, input without a label), magic values, swallowed errors, floating promises and code left dead by the change.

He does not comment on tests, formatting, import order, i18n or styling tokens. Skip them unless something is broken.

## How to write the comments

- Ask, don't order: "can we…?", "should we…?", "WDYT?". "I hope I'm not missing something!" goes on at most one comment per review, the one where you really lack context.
- Pick a severity per comment: Non blocking for most, Suggestion for ideas, Must fix only for wrong data, extra requests or broken behaviour.
- One comment per issue. On the next occurrence write only "same here".
- Short, concise and nonchalant: one or two sentences, often ending with "!". Name the issue and the ask; leave out the reasoning chain. Code sketches in plain fenced blocks, not GitHub `suggestion` blocks.
- Out-of-scope ideas: "we can handle this in a separate ticket".

## Output

A markdown numbered list, most severe first; he picks what to post by these numbers. Each item starts with its severity and short location, then the full clickable path, then the comment as a quote:

```
1. 🔴 Must fix · `useThing.ts:12`
   `src/hooks/useThing.ts:12`
   > this is doing an extra request every render, can we read `country` from the entity instead?

2. 🟡 Non blocking · `File.tsx:42`
   `src/components/File.tsx:42`
   > should we remove this comment? It is self-explanatory
   Same here: `src/components/File.tsx:57`

3. 🔵 Suggestion · `useCart.ts:30`
   `src/hooks/useCart.ts:30`
   > `total` is just `items.length`, we can handle this in a separate ticket!
```

- Severity leads the item (🔴 Must fix, 🟡 Non blocking, 🔵 Suggestion), so the quoted comment starts straight with the content.
- Repeats of an issue go on a `Same here:` line under the first item instead of a new item.
- Code sketches go in a fenced block under the quote.

After a `---` line, end with a bold one-line verdict in his style: "LGTM 👍🏼", "clean job 🔥", or "a few non-blocking comments, otherwise LGTM!". If nothing needs a comment, say so.

## Pending review

When the input was a PR, he approves what goes to GitHub: post only what he picks. Show him the full review first, then ask with the question tool, with the full review in each option's `preview` too, so he sees it while he picks.

At least one comment:

1. **Post all** (recommended): every comment goes into the pending review.
2. **Post some**: he types the item numbers in Other, for example `1, 3`; only those go into the pending review.
3. **Approve PR**: approve as below, with no comments.

No comments:

1. **Approve PR** (recommended): `gh pr review <n> --approve --body "<verdict>"`. Done when gh confirms the approval; reply with the PR link.
2. **Skip**: post nothing.

A pending review is a draft only he can see; he edits, picks Approve / Comment / Request changes and submits it on GitHub. Create it with one call and no `event` field, which is what keeps it pending:

```sh
gh api repos/{owner}/{repo}/pulls/{n}/reviews --method POST --input review.json
```

```json
{
  "commit_id": "<headRefOid from gh pr view --json headRefOid>",
  "comments": [
    { "path": "src/hooks/useThing.ts", "line": 12, "side": "RIGHT", "body": "**Must fix:** this is doing an extra request…" }
  ]
}
```

- One inline comment per item, on its exact line; each `Same here:` location gets its own comment with body "same here".
- Body: severity label in bold without the emoji (`**Non blocking:**`), then the quote text and any code sketch, unchanged.
- Use `start_line` + `line` for a comment on a range, `"side": "LEFT"` for a deleted line.
- Inline comments only land on lines inside the diff. Put any item outside it in the review `body` as `path:line` plus the comment.
- Write `review.json` to a temp dir and delete it after.
- GitHub allows one pending review per person per PR. On a 422 about an existing pending review, tell him to submit or discard it and offer to retry.

Done when the call returns `"state": "PENDING"`: reply with the PR link and the count of comments posted, and remind him to submit it on GitHub.
