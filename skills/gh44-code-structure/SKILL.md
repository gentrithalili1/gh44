---
name: gh44-code-structure
description: Gentrit's rules for organizing TypeScript and React code. Use when creating, moving, splitting or reviewing components, hooks, utils, types or folders in a TS/React codebase.
---

# Code structure

Repository rules win on a conflict. Follow the repository and mention the conflict in one line.

## Unit shape

- A unit is a folder for one component or one hook. A scene and `src` are units too.
- Required: `Thing.tsx`, `Thing.test.tsx`, `index.ts`. Optional: `Thing.elements.tsx` (JSX only, no hooks), `messages.ts`, `types.ts`, `components/`, `hooks/`, `utils/`.
- `components/` and `hooks/` hold units only. `utils/` holds pure files only. `index.ts` only re-exports.
- Never invent buckets such as `lib/`, `store/`, `shared/` or `features/`.

## Components

- Write function components only, never classes (enforced by `brain/no-class-component`).
- Name the props interface after the component (enforced by `brain/component-props-name`):

```tsx
interface MyComponentProps {
  title: string
}

function MyComponent({ title }: MyComponentProps) {
  return <h2>{title}</h2>
}
```

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
