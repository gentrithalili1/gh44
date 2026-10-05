# Agent Brain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every Claude Code session, in any repository, loads Gentrit's way of working from `~/agent-brain` and learns from his corrections.

**Architecture:** A small core `CLAUDE.md` is symlinked to `~/.claude/CLAUDE.md` and loads in every session. Topic rules are skills, so only their descriptions stay in context until a task needs them. One SessionStart hook enforces the core's line budget. `/learn` sorts new lessons into the right layer and writes them without committing.

**Tech Stack:** bash, jq, Claude Code memory, skills and hooks.

**Spec:** `docs/specs/2026-10-05-agent-brain-design.md`

## Global Constraints

- Never commit, stage or push in `~/agent-brain`. Gentrit reviews with `git diff` and commits himself.
- `CLAUDE.md` must be 60 lines or fewer.
- `install.sh` never overwrites a real file and backs up `settings.json` before changing it.
- `install.sh` changes nothing on a second run.
- No Join-specific content in the brain.
- Repository rules win on code conventions. The brain wins on workflow, communication, verification and safety.

## Review Focus

- `~/.claude/settings.json` does not exist yet. `install.sh` must create it with the hook. Covered in Task 5.
- A real directory already exists at `~/.claude/skills/<name>`. `install.sh` must stop and leave it untouched. Covered in Task 5.
- `install.sh` is run from another working directory. Paths must resolve from the script's location. Covered in Task 5: the test runs the script by absolute path from `/`.
- `CLAUDE.md` is missing when the hook runs. The hook must print nothing and exit 0. Covered in Task 1.
- `settings.json` already holds plugin hooks for the same event. They must survive. Covered in Task 5.

---

### Task 1: Budget check hook

**Files:**

- Create: `hooks/budget-check.sh`
- Test: `tests/budget-check.test.sh`

**Interfaces:**

- Produces: `hooks/budget-check.sh [file]`. It reads `file`, which defaults to `$HOME/.claude/CLAUDE.md`. It always exits 0. When the file has more than 60 lines, it prints one line containing `<n> lines`. Otherwise it prints nothing.

- [ ] **Step 1: Write the failing test** in `tests/budget-check.test.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$BRAIN/hooks/budget-check.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"

seq 60 > "$tmp/ok.md"
[ -z "$("$HOOK" "$tmp/ok.md")" ] || fail "60 lines should be silent"

seq 61 > "$tmp/big.md"
"$HOOK" "$tmp/big.md" | grep -q "61 lines" || fail "61 lines should warn"

[ -z "$("$HOOK" "$tmp/missing.md")" ] || fail "missing file should be silent"

echo "PASS budget-check"
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `bash tests/budget-check.test.sh`
Expected: an error, because `hooks/budget-check.sh` does not exist.

- [ ] **Step 3: Implement** `hooks/budget-check.sh`

```bash
#!/usr/bin/env bash
# SessionStart hook: tells Claude when the always-loaded core grew past its budget.
file="${1:-$HOME/.claude/CLAUDE.md}"
limit=60
[ -f "$file" ] || exit 0
lines="$(wc -l < "$file" | tr -d ' ')"
if [ "$lines" -gt "$limit" ]; then
  echo "agent-brain: core CLAUDE.md is $lines lines (budget $limit). Suggest /learn tidy to the user."
fi
exit 0
```

Run: `chmod +x hooks/budget-check.sh tests/budget-check.test.sh`

- [ ] **Step 4: Run it and confirm it passes**

Run: `bash tests/budget-check.test.sh`
Expected: `PASS budget-check`

- [ ] **Step 5: Leave uncommitted for review**

---

### Task 2: Core CLAUDE.md, inbox and log

**Files:**

- Create: `CLAUDE.md`, `inbox.md`, `log.md`

**Interfaces:**

- Produces: the `## Topic skills` heading in `CLAUDE.md`. `/learn` adds new skills to it. Produces the inbox header line `<!-- items below -->`. `/learn ingest` processes only what comes after that line.

- [ ] **Step 1: Write** `CLAUDE.md`

```md
# How I work

I'm Gentrit, a frontend engineer working mostly in React and TypeScript. These rules apply in every repository.

## Precedence

- Repository `CLAUDE.md` / `AGENTS.md` wins on code conventions: layout, naming, test style, libraries.
- These rules win on how to work with me: communication, workflow, verification, safety.
- On a conflict, follow the repository and say so in one line.

## Communication

- Keep answers short. Lead with the result.
- Act, don't ask. Ask only for irreversible, security, data or billing choices.

## Workflow

- Big task: break it into a short step-by-step plan first, so I understand it and we stay in sync. Small task: just do it.
- Read the code before proposing a change. Make the smallest correct change.
- Verify before saying done: run the smallest check that proves it and report the result. If you could not verify, say so.

## Code

- Fix the types or the code under test. Never silence them: no `as` beyond `as const`, no lint-disable comments.
- Comment only complicated logic, and keep it short. Never comment trivial changes such as a new property, import or rename.

## Topic skills

Load the matching skill before starting the work:

- `code-structure`: creating, moving or splitting TS/React files, components and hooks.

## Learning

- When I correct you or state a preference, run `/learn` with it.
- My brain repo is `~/agent-brain`. Never commit there; I review with `git diff`.
```

- [ ] **Step 2: Write** `inbox.md`

```md
# Inbox

Paste raw rules, notes and links below the marker. Run `/learn ingest` to sort them.

<!-- items below -->
```

- [ ] **Step 3: Write** `log.md`

```md
# Learning log

Append-only. One line per lesson: date | file | action | rule | why, source.

- 2026-10-05 | CLAUDE.md | added | initial core rules | stated in setup session
- 2026-10-05 | skills/code-structure | added | structure rules | "Frontend Structure Rules" artifact
```

- [ ] **Step 4: Verify the budget**

Run: `wc -l < CLAUDE.md && hooks/budget-check.sh CLAUDE.md`
Expected: a number of 60 or less, and no output from the hook.

- [ ] **Step 5: Leave uncommitted for review**

---

### Task 3: `learn` skill

**Files:**

- Create: `skills/learn/SKILL.md`

**Interfaces:**

- Consumes: the `## Topic skills` heading in `CLAUDE.md`, the `<!-- items below -->` marker in `inbox.md`, the line format of `log.md`, and `install.sh` from Task 5 for linking new skills.

- [ ] **Step 1: Write** `skills/learn/SKILL.md`

```md
---
name: learn
description: Save how Gentrit works into ~/agent-brain. Use when he corrects you, states a preference or a rule, says "learn this" or "remember this", or runs /learn, /learn ingest or /learn tidy.
---

# Learn

The brain repo is `~/agent-brain`. Write files there. Never commit, stage or push. He reviews with `git diff`.

## Modes

- `/learn [lesson]` (capture): the lesson is the argument, or the latest correction in this session.
- `/learn ingest`: process each item below `<!-- items below -->` in `inbox.md`, then delete the processed items. Read links with the right tool: Artifact `read` for claude.ai artifacts, WebFetch for other URLs.
- `/learn tidy`: review `CLAUDE.md` and every `skills/*/SKILL.md`. Merge duplicates, resolve contradictions, remove stale rules. If `CLAUDE.md` is over 60 lines, move the most topic-specific rules into skills. List the rules that a script could check as hook candidates.

## Route each lesson (first match wins)

1. **Repository-specific** (names a repo, product, team or internal tool): do not put it in the brain. Save it to the current project's auto-memory and say so.
2. **Script-checkable** (a command, file pattern or tool call that must always or never happen): propose a hook in one line, naming the event, the matcher and the check. Write it to `hooks/` and register it in `install.sh` only after he agrees. When a hook enforces a rule, delete the rule's text.
3. **Applies to some work only** (a language, framework, file type or task type): add it to the matching `skills/<topic>/SKILL.md`. If no skill matches, create `skills/<topic>/SKILL.md`. Its description must say when to load it. Add the skill to `## Topic skills` in `CLAUDE.md`, then run `~/agent-brain/install.sh` to link it.
4. **Applies to every session**: add it to `CLAUDE.md` under the heading that fits.

## Write the rule

- Write one imperative line, concrete. Add an example only when the rule is unclear without one.
- Search the target file first. If a rule overlaps, merge into it. If a rule contradicts, replace it and mention the old one.
- Keep `CLAUDE.md` at 60 lines or fewer. If an addition would go over, move topic-specific rules into a skill.

## Record

Append one line to `log.md`:

`- YYYY-MM-DD | <file> | <added|merged|replaced|removed> | <rule> | <why, source>`

## Report

Report one line per lesson, for example `Learned: skills/code-structure +1`. Nothing else.
```

- [ ] **Step 2: Verify the frontmatter**

Run: `head -4 skills/learn/SKILL.md`
Expected: the lines `name: learn` and `description: ...` appear between `---` lines.

- [ ] **Step 3: Leave uncommitted for review**

---

### Task 4: `code-structure` skill (React way of working)

**Files:**

- Create: `skills/code-structure/SKILL.md`

- [ ] **Step 1: Write** `skills/code-structure/SKILL.md`. This is the "Frontend Structure Rules" artifact compressed to rules.

```md
---
name: code-structure
description: Gentrit's rules for organizing TypeScript and React code. Use when creating, moving, splitting or reviewing components, hooks, utils, types or folders in a TS/React codebase.
---

# Code structure

Repository rules win on a conflict. Follow the repository and mention the conflict in one line.

## Unit shape

- A unit is a folder for one component or one hook. A scene and `src` are units too.
- Required: `Thing.tsx`, `Thing.test.tsx`, `index.ts`. Optional: `Thing.elements.tsx` (JSX only, no hooks), `messages.ts`, `types.ts`, `components/`, `hooks/`, `utils/`.
- `components/` and `hooks/` hold units only. `utils/` holds pure files only. `index.ts` only re-exports.
- Never invent buckets such as `lib/`, `store/`, `shared/` or `features/`.

## Placement: the importers decide

- One production importer: put the file inside that importer's unit.
- Two or more importers: put it in the lowest folder that contains all of them. Used by another app too: put it in a package.
- Tests, stories, `__mocks__` and a unit's own `index.ts` do not count as importers. Type-only, lazy and cross-app imports do.
- Never start a single-user file in a shared folder. When a second importer appears, lift the file to the lowest common parent in one commit.

## State flow

- State lives in the lowest unit whose children read it. Data goes down as props; events go up as callbacks.
- Never lift state to the root "in case".
- To reach far up the tree, use a prop first, then a context owned by the lowest common parent. Use alias imports only for pure code and shared hooks, never to reach a parent's state.

## File kinds

Imports go one way only: component, then hook, then pure.

- Pure (`utils/`, `types.ts`): functions over data. No React, i18n, toaster or Sentry.
- Shared hook: state, effects and I/O. It returns data, status, actions and typed outcomes. It never formats copy, uses i18n or toasts.
- Component: renders, formats copy, toasts and listens to the document. It does not own state that siblings share, and does not call I/O directly.
- A hook inside one component's `hooks/` may format copy. When it is lifted, remove the formatting and return data.
- A hook returns an outcome such as `{ status: 'failed', reason: 'rateLimited' }`. The component that started the action picks the copy and toasts.

## Homes

- Context provider and store: in the unit that owns the state, beside its hook.
- Constants: the nearest `utils/`. Types: `types.ts` of the lowest unit that needs them.
- GraphQL documents: beside the hook that runs them.
- Copy: `messages.ts` of the unit that renders it.
- Route entry: the scene's `index.ts`.

## Splitting hooks

- Split only when a hook has more than one reason to change and each piece is one nameable use case.
- Name pieces by use case (`useApplyDiscount`), not by layer (`useCartState`).
- Keep the old hook as a thin composer, so callers and tests keep working.
- No hooks under about 15 lines that only rename another hook. A size over about 200 lines is a reason to look, not a rule to split.

## Refactors

- Move-only changes and behavior changes go in separate PRs. A move must pass the existing tests unchanged.
- Restructure one feature at a time. Do not move files outside the current feature.
```

- [ ] **Step 2: Verify the frontmatter**

Run: `head -4 skills/code-structure/SKILL.md`
Expected: the lines `name: code-structure` and `description: ...` appear between `---` lines.

- [ ] **Step 3: Leave uncommitted for review**

---

### Task 5: `install.sh`

**Files:**

- Create: `install.sh`
- Test: `tests/install.test.sh`

**Interfaces:**

- Consumes: `CLAUDE.md`, `skills/*/` and `hooks/budget-check.sh` from Tasks 1 to 4.
- Produces: `install.sh`, which takes no arguments. It prints one line per change and nothing when there is nothing to do. It exits 1 if a target is in the way or if `jq` is missing.

- [ ] **Step 1: Write the failing test** in `tests/install.test.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
cd /

# Existing settings with a plugin hook on the same event
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude"
echo '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"plugin.sh"}]}]}}' > "$HOME/.claude/settings.json"
"$BRAIN/install.sh" > /dev/null
[ "$(readlink "$HOME/.claude/CLAUDE.md")" = "$BRAIN/CLAUDE.md" ] || fail "CLAUDE.md not linked"
[ "$(readlink "$HOME/.claude/skills/learn")" = "$BRAIN/skills/learn" ] || fail "learn not linked"
[ "$(readlink "$HOME/.claude/skills/code-structure")" = "$BRAIN/skills/code-structure" ] || fail "code-structure not linked"
jq -e --arg c "$BRAIN/hooks/budget-check.sh" \
  '[.hooks.SessionStart[].hooks[].command] == ["plugin.sh", $c]' "$HOME/.claude/settings.json" > /dev/null \
  || fail "hooks wrong: $(cat "$HOME/.claude/settings.json")"
ls "$HOME/.claude/" | grep -q 'settings.json.bak.' || fail "no backup"

# Second run changes nothing
[ -z "$("$BRAIN/install.sh")" ] || fail "second run was not a no-op"
jq -e '.hooks.SessionStart | length == 2' "$HOME/.claude/settings.json" > /dev/null || fail "hook duplicated"

# No settings.json yet
export HOME="$(mktemp -d)"
"$BRAIN/install.sh" > /dev/null
jq -e '.hooks.SessionStart | length == 1' "$HOME/.claude/settings.json" > /dev/null || fail "settings not created"

# Real files are never overwritten
export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude/skills/learn"
if "$BRAIN/install.sh" > /dev/null 2>&1; then fail "should refuse real skill dir"; fi
[ -d "$HOME/.claude/skills/learn" ] && [ ! -L "$HOME/.claude/skills/learn" ] || fail "real skill dir changed"

export HOME="$(mktemp -d)"
mkdir -p "$HOME/.claude"
echo mine > "$HOME/.claude/CLAUDE.md"
if "$BRAIN/install.sh" > /dev/null 2>&1; then fail "should refuse real CLAUDE.md"; fi
[ "$(cat "$HOME/.claude/CLAUDE.md")" = mine ] || fail "real CLAUDE.md changed"

echo "PASS install"
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `bash tests/install.test.sh`
Expected: an error, because `install.sh` does not exist.

- [ ] **Step 3: Implement** `install.sh`

```bash
#!/usr/bin/env bash
# Links the brain into ~/.claude and registers its hooks. Safe to run again.
set -euo pipefail

BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v jq > /dev/null || { echo "install: jq is required (brew install jq)" >&2; exit 1; }

link() {
  local source="$1" target="$2"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "install: $target exists and is not a link to $source; move it away first" >&2
    exit 1
  fi
  ln -s "$source" "$target"
  echo "linked $target"
}

add_hook() {
  local event="$1" command="$2" updated
  if jq -e --arg command "$command" '[.. | objects | select(.command? == $command)] | length > 0' "$SETTINGS" > /dev/null; then
    return
  fi
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  updated="$(jq --arg event "$event" --arg command "$command" \
    '.hooks[$event] = ((.hooks[$event] // []) + [{hooks: [{type: "command", command: $command}]}])' "$SETTINGS")"
  printf '%s\n' "$updated" > "$SETTINGS"
  echo "added $event hook: $command"
}

mkdir -p "$CLAUDE_DIR/skills"
link "$BRAIN/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
for skill in "$BRAIN"/skills/*/; do
  [ -d "$skill" ] || continue
  skill="${skill%/}"
  link "$skill" "$CLAUDE_DIR/skills/$(basename "$skill")"
done

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
add_hook SessionStart "$BRAIN/hooks/budget-check.sh"
```

Run: `chmod +x install.sh tests/install.test.sh`

- [ ] **Step 4: Run it and confirm it passes**

Run: `bash tests/install.test.sh && bash tests/budget-check.test.sh`
Expected: `PASS install` and `PASS budget-check`

- [ ] **Step 5: Leave uncommitted for review**

---

### Task 6: Install for real and verify

- [ ] **Step 1: Check the real targets are free**

Run: `ls -la ~/.claude/CLAUDE.md ~/.claude/skills/learn ~/.claude/skills/code-structure 2>&1`
Expected: `No such file or directory` for all three. If one exists, stop and ask Gentrit.

- [ ] **Step 2: Install**

Run: `~/agent-brain/install.sh`
Expected: three `linked` lines and one `added SessionStart hook` line.

- [ ] **Step 3: Confirm the plugin hooks survived**

Run: `jq '.hooks | keys' ~/.claude/settings.json`
Expected: the same 12 events as before, all still present.

- [ ] **Step 4: Check a fresh session**

Run: `cd /tmp && claude -p "List the rules from my user CLAUDE.md in 5 bullets, and name the skill you would load to create a React hook."`
Expected: the core rules (short answers, act don't ask, plan first, verify, comments) and `code-structure`.

- [ ] **Step 5: Hand over**

Tell Gentrit to run: `cd ~/agent-brain && git status && git diff`, then commit and push himself.
