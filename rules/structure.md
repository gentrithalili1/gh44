# Code structure

## Unit shape

- A unit is a folder for one component or one hook. A page (route) and `src` are units too.
- Required: `Thing.tsx`, `Thing.test.tsx`, `index.ts`. Optional: `Thing.elements.tsx` (the component's presentational building pieces: no hooks, copy or logic), `messages.ts`, `types.ts`, `components/`, `hooks/`, `utils/`.
- `components/` and `hooks/` hold units only. `utils/` holds pure files only. `index.ts` only re-exports.
- Presentational pieces (style props, passthrough props, children) go in `Thing.elements.tsx`. A piece moves to `components/` once it needs a hook, a handler, logic, copy or its own test.
- Keep to the folders above (enforced by `brain/no-generic-folders`).

## Components

- Order a component body: hooks, then derived values, then handlers, then early returns right before the JSX. Handlers sit below the data they read.
- Many derived values: move each one into the child component whose JSX reads it; group values about one thing into a pure `get*` util (`getCartSummary(cart)`); derive from server data in the query hook's `select` with a module-level function. Keep one-liners inline.

## Splitting hooks

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

## Refactors

- Move-only changes and behavior changes go in separate PRs. A move must pass the existing tests unchanged.
- Restructure one feature at a time. Do not move files outside the current feature.
