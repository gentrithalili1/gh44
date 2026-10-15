---
name: gh44-code-structure
description: Gentrit's rules for writing and organizing TypeScript and React code. Use when writing, reviewing, creating, moving or splitting components, hooks, utils, types, tests, data hooks, forms or folders in a TS/React codebase.
---

# TS and React code

## Types and exports

- `type` for every shape except props interfaces. String-literal unions or `as const` objects in place of `enum`.
- Named exports only (default only where the framework requires it). Import a unit through its folder's `index.ts`.

## Unit shape

- A unit is a folder for one component or one hook. A page (route) and `src` are units too.
- Required: `Thing.tsx`, `Thing.test.tsx`, `index.ts`. Optional: `Thing.elements.tsx` (the component's presentational building pieces: no hooks, copy or logic), `messages.ts`, `types.ts`, `components/`, `hooks/`, `utils/`.
- `components/` and `hooks/` hold units only. `utils/` holds pure files only. `index.ts` only re-exports.
- Presentational pieces (style props, passthrough props, children) go in `Thing.elements.tsx`. A piece moves to `components/` once it needs a hook, a handler, logic, copy or its own test.
- Keep to the folders above (enforced by `brain/no-generic-folders`).

## Components

- Write function components only (enforced by `brain/no-class-component`).
- Name the props interface after the component (enforced by `brain/component-props-name`):

```tsx
interface MyComponentProps {
  title: string
}

function MyComponent({ title }: MyComponentProps) {
  return <h2>{title}</h2>
}
```

- Order a component body: hooks, then derived values, then handlers, then early returns right before the JSX. Handlers sit below the data they read.
- Avoid `useEffect`: derive values during render, act in event handlers, fetch with data hooks.
- Leave memoization to the React Compiler: write plain values and functions; the compiler memoizes.
- One `variant` prop over several boolean props: `variant="primary"`, not `isPrimary isLarge`.
- `<button>` for actions, `<a>` or the router link for navigation, and a label for every input.
- Style from the design tokens or theme: every color, spacing, radius and font is a token.
- Loading shows a skeleton shaped like the final layout; errors hit an error boundary per route or section with a retry; empty lists show an empty state.
- Format dates, numbers and currency with Intl / react-intl in the user's locale, in the component. Store and pass dates as ISO strings in UTC.

## JSX

- Branch with an early return or a small extracted component, one ternary deep at most.
- Key list items by a stable id from the item.
- Render conditionally with a real boolean (`is*`, `has*`, `!!x`, a comparison) or `x ? <X /> : null`; a bare number renders `0`.

## Hooks

- Keep a hook's result whole: `const userStore = useUserStore()`, then `userStore.add()`.
- Move logic that can stand alone into its own hook or util. Give hooks short names.
- Split a hook only when it has more than one reason to change and each piece is one nameable use case.
- Name pieces by use case (`useApplyDiscount`), not by layer (`useCartState`).
- Keep the old hook as a thin composer, so callers and tests keep working.
- No hooks under about 15 lines that only rename another hook. A size over about 200 lines is a reason to look, not a rule to split.

## Placement: the importers decide

- One production importer: put the file inside that importer's unit.
- Two or more importers: put it in the lowest folder that contains all of them. Used by another app too: put it in a package.
- Tests, stories, `__mocks__` and a unit's own `index.ts` do not count as importers. Type-only, lazy and cross-app imports do.
- When a second importer appears, lift the file to the lowest common parent in one commit.

## State flow

- State lives in the lowest unit whose children read it. Data goes down as props; events go up as callbacks.
- To reach far up the tree, use a prop first, then a context owned by the lowest common parent. Use alias imports for pure code and shared hooks; a parent's state arrives through props or context.

## File kinds

Imports go one way only: component, then hook, then pure.

- Pure (`utils/`, `types.ts`): functions over data. No React, i18n, toaster or Sentry.
- Shared hook: state, effects and I/O. It returns data, status, actions and typed outcomes, and leaves copy, i18n and toasts to the component.
- Component: renders, formats copy, toasts and listens to the document. It does not own state that siblings share, and does not call I/O directly.
- A hook inside one component's `hooks/` may format copy. When it is lifted, remove the formatting and return data.
- A hook returns an outcome such as `{ status: 'failed', reason: 'rateLimited' }`. The component that started the action picks the copy and toasts.

## Homes

- Context provider and store: in the unit that owns the state, beside its hook.
- Constants: the nearest `utils/`. Types: `types.ts` of the lowest unit that needs them.
- GraphQL documents: beside the hook that runs them.
- Copy: `messages.ts` of the unit that renders it.
- Route entry: the page's `index.ts`.

## Data layer

- A fresh setup uses TanStack Query.
- Fetch through a data hook that wraps the client (`useJob`, `useSaveJob`). Components call the hook, not the client.
- Read server data straight from the hook; the client's cache is its single home.
- After a mutation, update the cache (return the changed entity, or write it) instead of refetching.

## Forms

- Where the repository has no form setup: a custom hook wrapping TanStack Form with a zod schema, in the form's own `hooks/` (`useJobForm`). The hook owns the schema, defaults and submit; the component renders the fields.

## Tests

- Testing Library queries by role or label (test ids only as a last resort), `userEvent` for interaction, MSW for the network. Write explicit assertions on what the user sees.

## SEO and rendering

- Prioritize SEO on public pages: server-render the content that should be indexed, use semantic HTML (one `h1`, headings in order, `<a href>` for navigation) and give every page its own title, description and image `alt`.
- Server components by default. Add `"use client"` only when a component needs state, effects, event handlers or browser APIs, and push it down to the smallest leaf that does.

## Refactors

- Move-only changes and behavior changes go in separate PRs. A move must pass the existing tests unchanged.
- Restructure one feature at a time. Do not move files outside the current feature.
