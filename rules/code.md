# Code

- Fix the types or the code under test. Never silence them: no `as` beyond `as const`, no lint-disable comments.
- Comment only complicated logic, and keep it short. Never comment trivial changes such as a new property, import or rename.
- Function components only; props interface named after the component (`CardProps` for `Card`).
- Avoid `useEffect`: derive values during render, act in event handlers, fetch with data hooks.
- A function with 2 or more parameters takes one params object.
- Keep a hook's result whole: `const userStore = useUserStore()`, then `userStore.add()`. Never destructure it.
- Move logic that can stand alone into its own hook or util. Give hooks short names.
- Name handlers `handle*` and booleans `is*`, `has*`, `should*`.
- Name new things like their siblings: same prefix and full domain word (`EditorAiEditedField` next to `EditorAiSession`, `trackJobAdSaved` not `trackAdSaved`).
- Hooks return data and outcomes; the component formats copy and toasts.
- The importers decide where a file lives; state lives in the lowest unit that reads it.
- These lines and more are enforced by my lint rules. Full structure guide: the `gh44-code-structure` skill.
