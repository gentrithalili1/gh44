---
name: gh44-pr
description: Ship finished work as a pull request: commit, push, open the PR and write its body. Use when Gentrit runs /gh44-pr or asks to open, create or describe a PR.
---

# PR

Adapted from Matt Pocock's `pr` skill, whose summary visuals come from Dex Horthy's `show-me` skill.

## Steps

1. **Check it is ready.** Run the smallest check that proves the change works (tests, type check, lint) and report the result. If `/gh44-review` has not run on this branch, offer it once before shipping.
2. **Branch.** On the default branch, create one first. Follow the repo's branch naming; take the ticket ID from the conversation or the branch name.
3. **Commit.** Stage only the files of this change. Follow the repo's commit style (`git log --oneline -10`).
4. **Push** with `git push -u origin HEAD`.
5. **Write the body.** If the repo has a PR template (`.github/pull_request_template.md` or similar), fill that in, using the sections below for its matching parts. Otherwise use the template below.
6. **Open it** with `gh pr create`, title in the repo's style, ticket linked. Reply with the PR link only.

## Template

```markdown
## Summary

<one or two lines, then the smallest visual that makes the change clear>

## How to test

- **Before:** <screenshot, output or failing test>
  **After:** <screenshot, output or passing test>
```

Keep the description short and plain enough to read in a minute: no preamble, no filler, no list of every changed file. Never add a Risk, Door or Blast radius section.

## Summary visuals

Pick the smallest view that makes the key point clear; usually one, rarely more than two. Keep only the calls, files, props and states that the reviewer needs.

- **Logic:** pseudocode.
- **Runtime flow:** a call tree (`submitForm` → `createSession` → `persistPrompt`).
- **UI structure:** a component tree with the hooks and boundaries that matter.
- **Refactor or new files:** a shallow file tree.
- **Interaction between parts:** a Mermaid sequence diagram.
- **What changed inside an existing shape:** a `diff` block of that tree, for example:

```diff
 <SessionPage>
   useSessionEvents()
   <SessionToolbar>
+    <RunSkillButton />
```

## How to test

Show before and after. A screenshot is best for a visual change; otherwise test output or console output. For a UI change, add the steps a reviewer should click through locally.
