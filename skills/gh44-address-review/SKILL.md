---
name: gh44-address-review
description: Work through review comments and failing CI on my open PR: triage, apply what I pick, verify, then ship and leave the replies pending.
argument-hint: "[PR link or number; default: the current branch's PR]"
disable-model-invocation: true
---

# Address review

For my own open PR. Someone else's PR is `/gh44-code-review`; merge conflicts are `/gh44-resolve-conflicts`. Nothing is committed, pushed or posted until I say "ship" in step 5.

## 1. Gather

- PR: `gh pr view <pr> --json number,url,id,headRefName,baseRefName`.
- Unresolved review threads with `gh api graphql`: `reviewThreads` where `isResolved` is false, with each thread's `id`, path, line and comments.
- Top-level comments from people: `gh pr view <pr> --comments`. Bot comments (Sonar, Sentry, Copilot) go on a separate **Bots** line.
- Failing checks: `gh pr checks <pr>`, logs with `gh run view <run> --log-failed`.

## 2. Check out

Work on the PR branch: this checkout if it is on that branch and clean, else a worktree as in `/gh44-resolve-conflicts` step 1. Run `git merge origin/<base>` only when CI fails because the branch is behind.

## 3. Triage

One numbered list, threads and comments first, then CI, then the Bots line:

```md
1. **Fix** · `path:line` · @reviewer
   > their comment
   <the change, in one line>

2. **Push back** · `path:line` · @reviewer
   > their comment
   <why not, in one line>

3. **CI** · <check> · <cause in one line> · Fix | Flaky | Pre-existing (<evidence>)
```

A take is **Fix**, **Push back** (they are wrong or it is out of scope) or **Question** (unclear what they want). Ask with the question tool: all fixes (recommended), some by number in Other, or none.

## 4. Apply and verify

Apply the picked items, then run `gh44-verifier` until `PASS`. Leave every change uncommitted.

## 5. Hand over

Draft a reply per item, in the voice of the "How to write the comments" section of `~/.claude/skills/gh44-code-review/SKILL.md`: a fix gets "done!" plus the change in a few words, a push back gets the reason, a question asks it.

```md
**Applied:** <numbers> · verifier PASS
**Replies:** <numbered drafts>

Review the changes in your editor, then say "ship".
```

On changes he asks for, apply them and run `gh44-verifier` again.

## 6. Ship (after "ship")

1. Commit in the repo's style as one commit for the round, then `git push`.
2. Create a pending review: GraphQL `addPullRequestReview` with the PR `id` and no `event`. Add each thread reply with `addPullRequestReviewThreadReply` and that review's id. Replies to top-level comments go in the review body, quoting the comment they answer.
3. On any API error, stop and give him the drafts to paste.

Reply with the PR link, the counts (fixed, pushed back, questions), and: "submit the pending review on GitHub as Comment, then re-request review".
