---
name: gh44-plan
description: Turn the clarified conversation or a ticket into a plan of tracer-bullet slices for /gh44-implement.
argument-hint: "[Linear ticket, if not already in the conversation]"
disable-model-invocation: true
---

# Plan

Synthesize what is already settled: the conversation, the ticket and the code. Clarify decided _what_ to build; the plan decides _how_.

## 1. Gather

If a ticket is passed and not yet in context, read it (read-only on Linear and Sentry). Explore the code the change touches.

Ask the open questions the ticket and conversation leave in rounds, the `grilling` way: numbered, each with your recommended answer, worded so "yes" accepts it. No question tool. Repeat until none is left.

Done when you can name every unit (component, hook, page) the change creates or modifies, placed by the structure rules.

## 2. Seams

Pick the seams the tests will hook into. Prefer existing seams and the highest one possible; the ideal number is one.

Done when every acceptance criterion is testable at a named seam.

## 3. Slices

Break the work into **tracer bullets**: each slice cuts a narrow, complete path through every layer it needs (data hook, component, test) and is verifiable on its own. Prefactoring comes first: make the change easy, then make the easy change. A wide refactor (one mechanical change across many call sites) is the exception: expand, migrate in batches, then contract.

Order the slices so every slice lands after the slices it depends on.

When the work is a single slice, say the task is small and skip to `/gh44-implement`.

More than 6 slices: the ticket is too big for one session. Group the slices into sub-tickets, each shippable on its own, and present the split below instead of the plan. Once he has created them, plan only the first one.

```md
**Too big for one session:** <n> tasks. Suggested split:

**A. <ticket title>** · tasks <1-4>
<ticket description: what it delivers, from the user's side>

- [ ] <acceptance criterion>

**B. <ticket title>** · tasks <5-8> · after A
...

**Next:** create these in Linear. We plan and build A here. After its `/gh44-create-pr`, run `/gh44-handoff B`, then start B in a fresh session with `/gh44-plan <B ticket>`.
```

## 4. Present

A task is one slice, shown in plain words.

```md
**Goal:** <what the ticket fixes or adds, one line>
**Approach:** <the main decisions, 1-3 lines>
**Tested at:** <the seam in plain words, e.g. render CartPage with MSW>

**Tasks** (one slice each, built in order)

1. <task>: <what it delivers> · <units touched>
   - [ ] <acceptance criterion>
2. <task>: ...

**Out of scope:** <what this plan leaves out>
```

Then ask: change the approach, the test spot, or any task?

## 5. Approve

Revise until he approves; approving also confirms the seam for `tdd`. The approved plan stays in this session as the brief for `/gh44-implement`, which builds the tasks in order. For a fresh session, `/gh44-handoff` carries it.
