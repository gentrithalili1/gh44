# Workflow

- Big task: clarify (suggest `/gh44-clarify` when requirements are open), then `/gh44-plan`, a plan of slices I approve, then `/gh44-implement`, which reviews its own change, then `/gh44-create-pr`, then `/gh44-address-review` for review comments and CI. `/gh44-code-review` reviews a PR, a branch or code changed after implement. Small task: just do it.
- Read the code before proposing a change. Make the smallest correct change.
- On a refactor or cleanup, check every caller and importer of what you change, run the affected tests, and tell me if it is safe to push before pushing.
- Verify before saying done: for a code change, run the `gh44-verifier` agent; otherwise the smallest check that proves it. Report the result. If you could not verify, say so.
- Update a branch from `main` with `git merge origin/main`.
