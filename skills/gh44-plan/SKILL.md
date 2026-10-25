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

Give each slice its **blocking edges**: the slices that must land before it.

When the work is a single slice, say the task is small and skip to `/gh44-implement`.

## 4. Present

```md
**Seams:** <seam>: <why it is the right place to test>

**1. <slice title>** · blocked by: none
Delivers: <behaviour the user sees, or a test proves>
Touches: <units created or modified>

- [ ] <acceptance criterion>

**2. <slice title>** · blocked by: 1
...

**Out of scope:** <what this plan deliberately leaves out>
```

Then ask: is the granularity right, are the blocking edges right, should any slice be merged or split?

## 5. Approve

Revise until he approves. The approved plan stays in this session as the brief for `/gh44-implement`, which works the **frontier** (slices whose blockers have landed) in order. For a fresh session, `/gh44-handoff` carries it.
