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
- 2026-10-06 | rules/communication.md | replaced | casual short answers; ask with options only when unsure on long tasks | user request
- 2026-10-06 | rules/learning.md + skills/learn | replaced | approve then write, commit, push; very sure plain rules skip approval | user request
- 2026-10-06 | rules/code.md + lint/rules | added | handle* handlers, is/has/should booleans, avoid useEffect, params object for 2+ params, keep hook results whole, extract standalone logic, short hook names, index re-export only, no generic folders | user request
- 2026-10-06 | hooks/load-structure | added | inject code-structure guide on first TS edit per session | skill loading was not guaranteed
- 2026-10-06 | skills/gh44-review | added | review like gentrithalili1, from 57 comments on 31 PRs | user request
- 2026-10-07 | rules/communication.md | replaced | ask with options and a recommendation whenever there are multiple real options (was: only on long tasks) | /learn ingest, his edit of item 5
- 2026-10-07 | hooks/capture-corrections | merged | skip system-generated prompts starting with `<` | /learn ingest: agent messages and hook notices filled the inbox
- 2026-10-07 | repo | replaced | renamed agent-brain to GH44 (~/gh44, github gentrithalili1/gh44, .gh44.json opt-out) | user request
- 2026-10-06 | hooks/capture-corrections + .gitignore | replaced | capture only don't, never, always, stop, prefer, not like this; inbox.md is local and untracked, install.sh creates it | user request
- 2026-10-07 | skills/gh44-review/SKILL.md | replaced | Output: numbered items with severity heading, path line, quoted comment, folded 'Same here', bold verdict | old flat path list was hard to follow, Gentrit via /gh44-learn
- 2026-10-07 | rules/code.md | added | Name new things like their siblings: same prefix and full domain word | Gentrit renamed AiEditedField→EditorAiEditedField and Ad→JobAd in jobs-app THU-3518
- 2026-10-07 | skills/gh44-pr/SKILL.md | replaced | Drop Risk/Door/Blast radius; keep the description short, no filler | Gentrit via /gh44-learn after PR #14191
- 2026-10-09 | skills/gh44-create-pr, skills/gh44-review-pr | renamed | from gh44-pr and gh44-review | Gentrit request
- 2026-10-09 | rules/code.md | replaced | Sibling-naming examples made generic (CartItemList, trackInvoicePaid) | Gentrit: old examples were project-specific
- 2026-10-09 | rules/code.md | added | Component body order: hooks, derived values, handlers, early returns, JSX | Gentrit request, reviewed via question tool
- 2026-10-09 | skills/gh44-code-structure/SKILL.md | moved | Component body order moved here from rules/code.md | Gentrit: belongs in code structure
