---
name: gh44-create-pr
description: Ship finished work as a pull request: verify, commit, push and open it. Use when Gentrit runs /gh44-create-pr or asks to open or create a PR.
---

# Create PR

## Steps

1. **Check it is ready.** Run the `gh44-verifier` agent and report its result. If neither `/gh44-implement` nor `/gh44-code-review` reviewed these changes, offer `/gh44-code-review` once before shipping.
2. **Branch.** On the default branch, create one first. Follow the repo's branch naming; take the ticket ID from the conversation or the branch name.
3. **Commit.** Stage only the files of this change. Follow the repo's commit style (`git log --oneline -10`).
4. **Push** with `git push -u origin HEAD`.
5. **Write the body.** Call the Skill tool with "pr". If the repo has a PR template (`.github/pull_request_template.md` or similar), fill that in instead, using `pr`'s sections for its matching parts. For a UI change, add under Evidence the steps a reviewer should click through locally. Under Merge Danger, leave out the **Door** and **Blast Radius** lines; write only the risks of merging.
6. **Open it** with `gh pr create`, title in the repo's style, ticket linked. Reply with the PR link only.
