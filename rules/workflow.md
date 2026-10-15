# Workflow

- Big task: clarify (suggest `/gh44-grill-me` when requirements are open), then a short step-by-step plan I approve, then execute, then offer `/gh44-review-pr` before `/gh44-create-pr`. Small task: just do it.
- Read the code before proposing a change. Make the smallest correct change.
- On a refactor or cleanup, check every caller and importer of what you change, run the affected tests, and tell me if it is safe to push before pushing.
- Verify before saying done: for a code change, run the `gh44-verifier` agent; otherwise the smallest check that proves it. Report the result. If you could not verify, say so.
- Update a branch from `main` with `git merge origin/main`.
