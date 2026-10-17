---
name: gh44-resolve-conflicts
description: Resolve a PR's merge conflicts with its base, show me the resolutions, push after I approve.
argument-hint: "<PR link or number>"
disable-model-invocation: true
---

# Resolve conflicts

Nothing is pushed until I approve in step 5.

1. **Check out the PR.** Read its branch and base with `gh pr view <pr> --json headRefName,baseRefName,url`, then `git fetch origin`. If the branch is already checked out in a clean worktree, work there. Otherwise `git worktree add <dir>/<name> <branch>`, where `<dir>` is what the repo's `AGENTS.md`/`CLAUDE.md` says, else `.worktrees`, and `<name>` is the branch with `/` replaced by `-`. Then run `"$(dirname "$(readlink ~/.claude/CLAUDE.md)")/hooks/prepare-worktree.sh" <path> <main checkout>` in the background (it copies `.env*` files and installs dependencies); check it finished before step 4.
2. **Merge the base in** with `git merge origin/<base>`. Merging keeps the push a normal push.
3. **Resolve every conflict.** For each file, read both sides and the commits that touched it on each side (`git log --oneline origin/<base>...HEAD -- <file>`), and keep both intents. Regenerate lockfiles and generated code with the repo's own command instead of editing them by hand. When both sides changed the same logic in different ways, ask me with the options and your recommendation. Done when `git diff --name-only --diff-filter=U` is empty and no conflict markers are left.
4. **Verify, scoped to the conflicted files.** Commit the merge locally with git's default merge message. Lint the conflicted files only, then typecheck and test only the packages that contain them (`pnpm --filter <pkg>` / the package's own scripts, tests via related-files mode), one command at a time. A whole-monorepo typecheck, build or test run is out of scope. Report the results.
5. **Show me the resolutions** with `git show --remerge-diff HEAD`: only how each conflict was decided, not everything the base brought in. Add one line per file on why. Wait for my approval; on changes, fix and amend the unpushed merge commit.
6. **Push** with `git push`, reply with the PR link, and remove the worktree if you created it.
