# Code

- Make types and lint pass by fixing the code: narrow `unknown` where `any` tempts, use `as const` as the only assertion, keep every lint rule on.
- `type` for every shape except props interfaces. String-literal unions or `as const` objects in place of `enum`.
- Named exports only (default only where the framework requires it). Import a unit through its folder's `index.ts`.
- Model state as a status union: `status: 'idle' | 'loading' | 'error' | 'success'`, not `isLoading` + `isError`.
- Handle every case of a union: `switch` with a `never` check in `default`, so a new variant breaks the build.
- Name magic strings and numbers as constants.
- Every `catch` handles, rethrows or reports; report to Sentry with context when the project uses Sentry.
- `await` every promise, or mark a deliberate fire-and-forget with `void`.
- Delete dead code and unused exports in the same change that orphans them.
- Comment only complicated logic, and keep it short.
- A function with 2 or more parameters takes one params object.
- Name handlers `handle*` and booleans `is*`, `has*`, `should*`.
- Name new things like their siblings: same prefix and full domain word (`CartItemList` next to `CartSummary`, not `ItemList`; `trackInvoicePaid` not `trackPaid`).
- Where the repository has not chosen a stack, go TanStack first (Start, Router, Query, Table, Store, Form) with TypeScript, pnpm, shadcn/ui, oxlint and oxfmt.
- Many of these are enforced by my lint hooks.

## Components

- Function components only; props interface named after the component (`CardProps` for `Card`), both enforced by my lint hooks.
- Avoid `useEffect`: derive values during render, act in event handlers, fetch with data hooks.
- Leave memoization to the React Compiler: write plain values and functions; the compiler memoizes.
- Keep a hook's result whole: `const userStore = useUserStore()`, then `userStore.add()`.
- Move logic that can stand alone into its own hook or util. Give hooks short names.
- One `variant` prop over several boolean props: `variant="primary"`, not `isPrimary isLarge`.
- `<button>` for actions, `<a>` or the router link for navigation, and a label for every input.
- Style from the design tokens or theme: every color, spacing, radius and font is a token.
- Loading shows a skeleton shaped like the final layout; errors hit an error boundary per route or section with a retry; empty lists show an empty state.
- Format dates, numbers and currency with Intl / react-intl in the user's locale, in the component. Store and pass dates as ISO strings in UTC.

## JSX

- Branch with an early return or a small extracted component, one ternary deep at most.
- Key list items by a stable id from the item.
- Render conditionally with a real boolean (`is*`, `has*`, `!!x`, a comparison) or `x ? <X /> : null`; a bare number renders `0`.

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
