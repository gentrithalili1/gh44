# Code

- Fix the types or the code under test. Never silence them: no `any` (use `unknown` and narrow), no `as` beyond `as const`, no lint-disable comments.
- `type` for every shape except props interfaces. String-literal unions or `as const` objects in place of `enum`.
- Named exports only (default only where the framework requires it). Import a unit through its folder's `index.ts`.
- Model state as a status union, not a pile of booleans: `status: 'idle' | 'loading' | 'error' | 'success'`, not `isLoading` + `isError`.
- Handle every case of a union: `switch` with a `never` check in `default`, so a new variant breaks the build.
- No magic strings or numbers: name them as constants in the nearest `utils/`.
- Never swallow errors: every `catch` handles, rethrows or reports. Report to Sentry with context when the project uses Sentry.
- No floating promises: `await` them, or mark a deliberate fire-and-forget with `void`.
- Delete dead code and unused exports in the same change that orphans them.
- Comment only complicated logic, and keep it short. Never comment trivial changes such as a new property, import or rename.
- Function components only; props interface named after the component (`CardProps` for `Card`).
- Avoid `useEffect`: derive values during render, act in event handlers, fetch with data hooks.
- Leave memoization to the React Compiler: write plain values and functions, no `useMemo`, `useCallback` or `memo`.
- A function with 2 or more parameters takes one params object.
- Keep a hook's result whole: `const userStore = useUserStore()`, then `userStore.add()`. Never destructure it.
- Move logic that can stand alone into its own hook or util. Give hooks short names.
- Name handlers `handle*` and booleans `is*`, `has*`, `should*`.
- Name new things like their siblings: same prefix and full domain word (`CartItemList` next to `CartSummary`, not `ItemList`; `trackInvoicePaid` not `trackPaid`).
- Hooks return data and outcomes; the component formats copy and toasts.
- The importers decide where a file lives; state lives in the lowest unit that reads it.
- These lines and more are enforced by my lint rules. Full structure guide: the `gh44-code-structure` skill.

## JSX

- No nested ternaries in JSX: extract a small component, or use an early return.
- Never use an array index as `key`; use a stable id from the item.
- Render conditionally with a real boolean (`is*`, `has*`, `!!x`, a comparison) or `x ? <X /> : null`. Never `count && <X />`: it renders `0`.
- One `variant` prop over several boolean props: `variant="primary"`, not `isPrimary isLarge`.
- `<button>` for actions, `<a>` or the router link for navigation, and a label for every input.

## Tests

- Testing Library queries by role or label (test ids only as a last resort), `userEvent` for interaction, MSW for the network. Assert on what the user sees; no snapshot tests.

## SEO and rendering

- Prioritize SEO on public pages: server-render the content that should be indexed, use semantic HTML (one `h1`, headings in order, `<a href>` for navigation) and give every page its own title, description and image `alt`.
- Server components by default. Add `"use client"` only when a component needs state, effects, event handlers or browser APIs, and push it down to the smallest leaf that does.

## Stack

- Follow the repository's stack. Where it has not chosen, TanStack first: Start, Router, Query, Table, Store, Form. With TypeScript, pnpm, shadcn/ui, oxlint and oxfmt.

## Data layer

- Follow the repository's data layer (Apollo, TanStack Query over REST, …) unless I ask otherwise. A fresh setup uses TanStack Query.
- Fetch through a data hook that wraps the client (`useJob`, `useSaveJob`). Components call the hook, not the client.
- Server data lives in the client's cache only: read it from the hook, never copy it into `useState` or a context.
- After a mutation, update the cache (return the changed entity, or write it) instead of refetching.

## Forms

- Follow the repository's form setup when it has one.
- Otherwise: a custom hook wrapping TanStack Form with a zod schema, in the form's own `hooks/` (`useJobForm`). The hook owns the schema, defaults and submit; the component renders the fields.
