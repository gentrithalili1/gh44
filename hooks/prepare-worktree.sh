#!/usr/bin/env bash
# Makes a new linked worktree ready to run: copies the main checkout's gitignored .env* files
# and installs dependencies from the lockfile. /gh44-implement --worktree and an editor's worktree-created hook call it.
# A repo replaces these steps with its own git-excluded .worktree-setup.sh in the main checkout.
# Usage: prepare-worktree.sh <worktree> <main checkout>
set -euo pipefail

worktree="${1:?worktree path required}"
main="${2:?main checkout path required}"

# Editors create worktrees on a detached HEAD: give it a branch named after its folder, from the remote's default branch.
name="$(basename "$worktree")"
# Some editors nest the checkout as <name>/<repo folder>.
[ "$name" = "$(basename "$main")" ] && name="$(basename "$(dirname "$worktree")")"
if ! git -C "$worktree" symbolic-ref -q HEAD > /dev/null && ! git -C "$worktree" show-ref -q --verify "refs/heads/$name"; then
  base="$(git -C "$worktree" symbolic-ref -q --short refs/remotes/origin/HEAD || true)"
  if [ -n "$base" ] && git -C "$worktree" fetch -q origin; then
    git -C "$worktree" switch -q --no-track -c "$name" "$base"
  else
    git -C "$worktree" switch -q -c "$name"
  fi
  echo "→ branch $name${base:+ from $base}"
fi

if [ -x "$main/.worktree-setup.sh" ]; then
  exec "$main/.worktree-setup.sh" "$worktree" "$main"
fi

# --directory lists an ignored folder (node_modules, worktrees) as one entry instead of every file in it.
copied=0
while IFS= read -r -d '' file; do
  case "$(basename "$file")" in .env*) ;; *) continue ;; esac
  [ -f "$main/$file" ] && [ ! -e "$worktree/$file" ] || continue
  mkdir -p "$(dirname "$worktree/$file")"
  cp -p "$main/$file" "$worktree/$file"
  copied=$((copied + 1))
done < <(git -C "$main" ls-files --others --ignored --exclude-standard --directory -z)
echo "→ $copied env files copied"

cd "$worktree"
if [ -f pnpm-lock.yaml ]; then
  install=(pnpm install --frozen-lockfile)
elif [ -f bun.lock ] || [ -f bun.lockb ]; then
  install=(bun install --frozen-lockfile)
elif [ -f yarn.lock ] && [ -f .yarnrc.yml ]; then
  install=(yarn install --immutable)
elif [ -f yarn.lock ]; then
  install=(yarn install --frozen-lockfile)
elif [ -f package-lock.json ]; then
  install=(npm ci)
else
  echo "✓ Worktree ready, no lockfile to install: $worktree"
  exit 0
fi
echo "→ ${install[*]}"
"${install[@]}"
echo "✓ Worktree ready: $worktree"
