# Learning log

Append-only. One line per lesson: date | file | action | rule | why, source.

- 2026-10-05 | CLAUDE.md | added | initial core rules | stated in setup session
- 2026-10-05 | CLAUDE.md | replaced | plan first only for big tasks | "Plan first should only be when we are planning a big task"
- 2026-10-05 | skills/code-structure | added | structure rules | "Frontend Structure Rules" artifact
- 2026-10-05 | skills/learn | merged | repo-specific skills live in the repo, git-excluded, never in the brain | "I dont want these in the agent brain, these are repo specific"
- 2026-10-05 | hooks/check-code + checks/rules | added | ast-grep checks: no-as-cast, no-lint-disable, pure-utils-no-react | deterministic checks requested
- 2026-10-05 | hooks/capture-corrections | added | auto-capture correction prompts into inbox.md | "it should learn from me"
- 2026-10-05 | hooks/check-changed + mark-turn | added | end-of-turn check of files changed this turn | edits through the shell skipped the PostToolUse check
- 2026-10-06 | hooks/check-changed | replaced | end-of-turn check counts only unstaged/untracked files, skips over 30 | flagged 5298 staged merge files on THU-3532
- 2026-10-06 | lint/eslint.config.js | added | personal ESLint rules (sort-imports auto-fix, no-explicit-any); repo config wins per rule | "priority is to repository settings, if not it should default to mine"
- 2026-10-06 | skills/code-structure + lint/rules | added | function components only; props interface named <Component>Props | "all should be functional components and the props should include the name of the component"
- 2026-10-06 | frontend/.agent-brain.json | added | rulesOff brain/component-props-name in Join (repo uses `Props`, 1200 vs 889) | repo settings win
- 2026-10-06 | lint/ | merged | ast-grep rules moved into ESLint (consistent-type-assertions, brain/no-lint-disable, brain/pure-utils); checks/ removed | "we should just keep the eslint, its easier to add new ones"
- 2026-10-06 | rules/ | replaced | core rules moved from CLAUDE.md into rules/<topic>.md, CLAUDE.md keeps identity and skill list | "move them to rules folder then, keep claude.md simple"
