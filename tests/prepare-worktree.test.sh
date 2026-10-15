#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$BRAIN/hooks/prepare-worktree.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
main="$tmp/main"
mkdir -p "$main/apps/web/node_modules/pkg"
git -C "$main" init -q -b main
printf '.env*\nnode_modules/\n.worktrees/\n' > "$main/.gitignore"
echo "tracked" > "$main/apps/web/index.ts"
git -C "$main" add . && git -C "$main" -c user.email=t@t -c user.name=t commit -qm init
echo "SECRET=1" > "$main/.env"
echo "API=main" > "$main/apps/web/.env.local"
echo "API=nested" > "$main/apps/web/node_modules/pkg/.env"
git -C "$main" worktree add -q "$main/.worktrees/ABC-1" --detach

worktree="$main/.worktrees/ABC-1"
echo "API=kept" > "$worktree/apps/web/.env.local"
out="$("$SCRIPT" "$worktree" "$main")"

[ "$(cat "$worktree/.env")" = "SECRET=1" ] || fail "root .env not copied"
[ "$(cat "$worktree/apps/web/.env.local")" = "API=kept" ] || fail "existing env file overwritten"
[ ! -e "$worktree/apps/web/node_modules/pkg/.env" ] || fail "env inside node_modules copied"
grep -q "no lockfile" <<< "$out" || fail "no lockfile must skip install: $out"
[ "$(git -C "$worktree" branch --show-current)" = "ABC-1" ] || fail "detached worktree must get a branch named after its folder"

# With a remote, the branch starts from the remote's default branch.
git clone -q "$main" "$tmp/clone"
git -C "$main" -c user.email=t@t -c user.name=t commit -q --allow-empty -m newer
git -C "$tmp/clone" fetch -q origin && git -C "$tmp/clone" remote set-head origin main > /dev/null
git -C "$tmp/clone" worktree add -q "$tmp/clone/.worktrees/ABC-2" --detach HEAD
"$SCRIPT" "$tmp/clone/.worktrees/ABC-2" "$tmp/clone" > /dev/null
! git -C "$tmp/clone/.worktrees/ABC-2" rev-parse -q --abbrev-ref "@{u}" > /dev/null 2>&1 || fail "new branch must not track the default branch"
[ "$(git -C "$tmp/clone/.worktrees/ABC-2" rev-parse HEAD)" = "$(git -C "$main" rev-parse HEAD)" ] || fail "branch must start from origin's default branch"

# A worktree nested as <name>/<repo folder> is named after <name>.
git -C "$main" worktree add -q "$main/.worktrees/ABC-4/main" --detach
"$SCRIPT" "$main/.worktrees/ABC-4/main" "$main" > /dev/null
[ "$(git -C "$main/.worktrees/ABC-4/main" branch --show-current)" = "ABC-4" ] || fail "nested worktree must be named after its parent folder"

# A worktree already on a branch keeps it.
git -C "$main" worktree add -q "$main/.worktrees/ABC-3" -b feature
"$SCRIPT" "$main/.worktrees/ABC-3" "$main" > /dev/null
[ "$(git -C "$main/.worktrees/ABC-3" branch --show-current)" = "feature" ] || fail "existing branch must be kept"

printf '#!/usr/bin/env bash\necho "custom $1 $2" > "$1/custom.txt"\n' > "$main/.worktree-setup.sh"
chmod +x "$main/.worktree-setup.sh"
rm "$worktree/.env"
"$SCRIPT" "$worktree" "$main" > /dev/null
[ "$(cat "$worktree/custom.txt")" = "custom $worktree $main" ] || fail "repo .worktree-setup.sh not run with both paths"
[ ! -e "$worktree/.env" ] || fail "generic steps must not run when the repo has its own setup"

"$SCRIPT" 2> /dev/null && fail "missing arguments must fail"

echo "PASS prepare-worktree"
