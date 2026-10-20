---
name: gh44-code-review
description: Review code the way Gentrit (gentrithalili1) reviews: a PR, a branch or local changes, against the repo's standards, his rules and the ticket. Use when he runs /gh44-code-review, or asks to review code "like me".
---

# gh44 code review

Two axes, reported separately so one cannot mask the other: **Standards** (does the code follow the rules that apply here?) and **Spec** (does it do what the ticket or plan asked?). The voice comes from his real review comments (57 comments on 31 PRs). Review what a person has to judge: anything tooling enforces (the repo's lint and types, and his lint hooks for casts, `any`, naming, effects, params, hook results, nested JSX ternaries, index keys and `&&` renders) is already covered, so skip it.

## Input

- A PR link or number: `gh pr diff <n>` and `gh pr view <n> --json title,body,author,headRefName,headRefOid`.
- Nothing given: the current branch against its base, `git diff $(git merge-base origin/main HEAD)`, plus untracked files (`git ls-files --others --exclude-standard`), each read in full as a new file.

Read the changed files around each hunk before commenting.

## Run in a fresh context

Unless you are the `gh44-reviewer` agent, find the spec first: the approved plan's acceptance criteria in this session; else the ticket linked in the PR body or named in the branch (`ABC-123`), read-only from Linear. Dispatch the agent with the input and the spec's criteria, and wait for its review. Show its output to him unchanged, then do the Finish step yourself.

## Gather

- **Standards sources:** every file in the repo that says how code is written: `CLAUDE.md` / `AGENTS.md` (root and in the changed folders), `CONTRIBUTING.md`, `CODING_STANDARDS.md`, `.cursor/rules/`, and docs folders about conventions.
- **Spec:** the acceptance criteria passed in; without them, the Spec section says "no spec found".

Done when you can list both before reading the diff.

## Standards: what to look for

Apply in this order of authority. A higher source wins: where the repo endorses something a lower one would flag, skip it.

### 1. Repo standards

Every place the diff breaks a documented repo rule. A documented rule can be Must fix.

### 2. His rules, where the repo is silent

His rules in `~/.claude/rules/code.md` and `~/.claude/rules/structure.md`: logic that could stand alone as a hook or util, long hook names, state lifted too high, boolean piles instead of a status union, non-exhaustive `switch`, boolean props instead of a `variant`, wrong element for the job (`div` with `onClick`, input without a label), magic values, swallowed errors, floating promises, and code left dead by the change.

### 3. His taste, most frequent first

1. **Comments that repeat the code.** JSDoc or inline comments that restate the code, narrate the ticket or explain history: ask to remove them.
2. **Re-created code.** A type, util, constant or validator that already exists in the repo or a shared package: point to it and ask to reuse or export it. Two places that must stay in sync should share one constant.
3. **Extra requests.** A new query for data that is already in props, an existing fragment or the cache: ask to add the field to the existing query or read it from what is passed in.
4. **Wrong file.** Code that doesn't follow the repo's file layout (its `AGENTS.md`/`CLAUDE.md` and sibling folders) or, where the repo is silent, my `~/.claude/rules/structure.md`: helper JSX, constants or non-hook logic in the wrong file. Reason: consistency.
5. **Is this needed?** An unneeded `try/catch`, an extra returned field, a rename that hides an API, an unfamiliar pattern: ask a short question, no fix needed.
6. **Readability.** A long condition becomes named booleans; a timer or rotation inside a component becomes its own hook. Sketch the fix in a plain code block.
7. **Behaviour.** If the change affects UI, say what to try locally and what could go wrong (stale error after submit, value overwritten on load).
8. **Modern React.** Prefer current APIs, for example `useEffectEvent` over a ref that mirrors a callback.

### 4. Smells

Fowler's smells (_Refactoring_, ch. 3), always 🔵 Suggestion, named as a heuristic ("possible Data Clumps"):

- **Mysterious Name**: a name that does not reveal what it does or holds → rename it.
- **Duplicated Code**: the same logic shape in more than one hunk or file of the change → extract the shared shape.
- **Data Clumps**: the same few props or params travelling together → one type.
- **Primitive Obsession**: a string or number standing in for a domain concept → its own small type or union.
- **Speculative Generality**: options, params or abstractions the ticket does not need → inline until a real need shows.
- **Shotgun Surgery**: one logical change forcing scattered edits → gather what changes together.
- **Divergent Change**: one file edited for several unrelated reasons → split it.
- **Middle Man**: a component, hook or function that only passes through → call the real target.

He does not comment on tests, formatting, import order, i18n or styling tokens. Skip them unless something is broken.

## Spec: what to look for

Against each acceptance criterion: (a) missing or partial, (b) implemented but wrong, (c) behaviour nobody asked for (scope creep). Quote the criterion for each finding. Severity: missing or wrong is Must fix, scope creep is Non blocking.

## How to write the comments

- Ask, don't order: "can we…?", "should we…?", "WDYT?". "I hope I'm not missing something!" goes on at most one comment per review, the one where you really lack context.
- Pick a severity per comment: Non blocking for most, Suggestion for ideas, Must fix only for wrong data, extra requests or broken behaviour.
- One item per issue. Every posted comment stands alone: on a repeat, name the issue in one short sentence (`same \`null\`/\`undefined\` mix here, can we pick one?`), never a bare "same here", since posted comments lose the first one's context.
- Short, concise and nonchalant: one or two sentences, often ending with "!". Name the issue and the ask; leave out the reasoning chain. Code sketches in plain fenced blocks, not GitHub `suggestion` blocks.
- Out-of-scope ideas: "we can handle this in a separate ticket".

## Output

Two sections, `### Standards` then `### Spec`, each a numbered list most severe first. Numbers run on across both sections, so he picks items by number. Each item starts with its severity and short location, then the full clickable path, then the comment as a quote, then its source:

```
### Standards

1. 🔴 Must fix · `useThing.ts:12`
   `src/hooks/useThing.ts:12`
   > this is doing an extra request every render, can we read `country` from the entity instead?
   Source: taste · Extra requests

2. 🟡 Non blocking · `File.tsx:42`
   `src/components/File.tsx:42`
   > can we use the `useJobQuery` wrapper here?
   Source: AGENTS.md › Data fetching
   Also at: `src/components/File.tsx:57`

### Spec

3. 🔴 Must fix · `JobForm.tsx:30`
   `src/pages/Job/JobForm.tsx:30`
   > the ticket says the salary is optional, but the form still requires it, should we drop the check?
   Source: ABC-123 › "Salary is optional"
```

- Severity leads the item (🔴 Must fix, 🟡 Non blocking, 🔵 Suggestion), so the quoted comment starts straight with the content.
- The `Source:` line is for him; it never goes into a posted comment.
- Repeats of an issue go on an `Also at:` line under the first item instead of a new item.
- Code sketches go in a fenced block under the quote.
- A section with nothing to report says so in one line.

After a `---` line, end with a bold one-line verdict in his style: "LGTM 👍🏼", "clean job 🔥", or "a few non-blocking comments, otherwise LGTM!".

## Finish

Whose code it is decides the ending. Compare the PR author (`author.login`) with `gh api user --jq .login`.

- **Someone else's PR:** the Pending review below. Never edit their code.
- **His own PR, or local changes:** ask with the question tool which numbered items to apply (all clear fixes, some by number, or none). Apply the picked ones, then run the `gh44-verifier` agent. Done when it returns `PASS`.

## Pending review

He approves what goes to GitHub: post only what he picks. Show him the full review first, then ask with the question tool, with the full review in each option's `preview` too, so he sees it while he picks.

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

- One inline comment per item, on its exact line; each `Also at:` location gets its own short comment that names the issue and the ask on its own.
- Body: severity label in bold without the emoji (`**Non blocking:**`), then the quote text and any code sketch, unchanged.
- Use `start_line` + `line` for a comment on a range, `"side": "LEFT"` for a deleted line.
- Inline comments only land on lines inside the diff. Put any item outside it in the review `body` as `path:line` plus the comment.
- Write `review.json` to a temp dir and delete it after.
- GitHub allows one pending review per person per PR. On a 422 about an existing pending review, tell him to submit or discard it and offer to retry.

Done when the call returns `"state": "PENDING"`: reply with the PR link and the count of comments posted, and remind him to submit it on GitHub.
