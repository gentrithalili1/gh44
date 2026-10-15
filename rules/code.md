# Code

- Make types and lint pass by fixing the code: narrow `unknown` where `any` tempts, use `as const` as the only assertion, keep every lint rule on.
- Model state as a status union: `status: 'idle' | 'loading' | 'error' | 'success'`, not `isLoading` + `isError`.
- Handle every case of a union: `switch` with a `never` check in `default`, so a new variant breaks the build.
- Name magic strings and numbers as constants in the nearest `utils/`.
- Every `catch` handles, rethrows or reports; report to Sentry with context when the project uses Sentry.
- `await` every promise, or mark a deliberate fire-and-forget with `void`.
- Delete dead code and unused exports in the same change that orphans them.
- Comment only complicated logic, and keep it short.
- A function with 2 or more parameters takes one params object.
- Name handlers `handle*` and booleans `is*`, `has*`, `should*`.
- Name new things like their siblings: same prefix and full domain word (`CartItemList` next to `CartSummary`, not `ItemList`; `trackInvoicePaid` not `trackPaid`).
- Where the repository has not chosen a stack, go TanStack first (Start, Router, Query, Table, Store, Form) with TypeScript, pnpm, shadcn/ui, oxlint and oxfmt.
