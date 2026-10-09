#!/usr/bin/env bash
set -euo pipefail
BRAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$BRAIN/hooks/check-code.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }

run_hook() {
  status=0
  output="$(jq -n --arg file "$1" '{tool_name: "Edit", tool_input: {file_path: $file}}' | "$HOOK" 2>&1)" || status=$?
}
new_repo() {
  repo="$(mktemp -d)"
  git -C "$repo" init -q
}
unsorted() { printf "import { b } from './b'\nimport { a } from 'zod'\n\nexport const x = [a, b]\n" > "$1"; }

# No lint setup in the repo: my import order is fixed silently
new_repo
unsorted "$repo/sorted.ts"
run_hook "$repo/sorted.ts"
[ "$status" -eq 0 ] || fail "fixable problems must not block: $output"
[ "$(head -1 "$repo/sorted.ts")" = "import { a } from 'zod'" ] || fail "imports not sorted: $(cat "$repo/sorted.ts")"

# The repository's formatter sorts imports: mine stays off
new_repo
printf '{ "sortImports": { "order": "asc" } }\n' > "$repo/.oxfmtrc.json"
unsorted "$repo/owned.ts"
run_hook "$repo/owned.ts"
[ "$(head -1 "$repo/owned.ts")" = "import { b } from './b'" ] || fail "repo formatter owns import order"

# Non-fixable rule is reported
new_repo
printf 'export const f = (value: any) => value\n' > "$repo/any.ts"
run_hook "$repo/any.ts"
[ "$status" -eq 2 ] || fail "any should block (status $status)"
echo "$output" | grep -q "any.ts:1 @typescript-eslint/no-explicit-any" || fail "any not reported: $output"

# The repository configures the rule (oxlint, through extends): mine stays off
new_repo
mkdir -p "$repo/configs"
printf '{ "rules": { "typescript/no-explicit-any": "off" } }\n' > "$repo/configs/base.json"
printf '{ "extends": ["./configs/base.json"] }\n' > "$repo/.oxlintrc.json"
printf 'export const f = (value: any) => value\n' > "$repo/any.ts"
run_hook "$repo/any.ts"
[ "$status" -eq 0 ] || fail "repo oxlint config owns no-explicit-any: $output"

# Only changed lines are reported
new_repo
printf 'export const old = (value: any) => value\n' > "$repo/legacy.ts"
git -C "$repo" add legacy.ts
git -C "$repo" -c user.email=t@t -c user.name=t commit -q -m init
printf 'export const fresh = (value: any) => value\n' >> "$repo/legacy.ts"
run_hook "$repo/legacy.ts"
echo "$output" | grep -q "legacy.ts:2 " || fail "new any not reported: $output"
echo "$output" | grep -q "legacy.ts:1 " && fail "legacy line reported: $output"

# Inline disable comments for unknown repo rules do not break the run
new_repo
printf '// eslint-disable-next-line some-plugin/unknown-rule\nexport const y = 1\n' > "$repo/directive.ts"
run_hook "$repo/directive.ts"
echo "$output" | grep -qi "definition for rule" && fail "unknown rule directive broke lint: $output"

# Components: function components only, props named after the component
new_repo
printf 'import { Component } from "react"\nexport class Card extends Component {}\n' > "$repo/Class.tsx"
run_hook "$repo/Class.tsx"
echo "$output" | grep -q "brain/no-class-component" || fail "class component not reported: $output"

printf 'interface ButtonProps { title: string }\nexport function Card(props: ButtonProps) { return null }\n' > "$repo/Card.tsx"
run_hook "$repo/Card.tsx"
echo "$output" | grep -q "Card.tsx:2 brain/component-props-name: .*CardProps" || fail "wrong props name not reported: $output"

printf 'interface Props { title: string }\nexport const Card = ({ title }: Props) => title\n' > "$repo/Arrow.tsx"
run_hook "$repo/Arrow.tsx"
echo "$output" | grep -q "brain/component-props-name" || fail "arrow component with Props not reported: $output"

printf 'interface CardProps { title: string }\nexport function Card({ title }: CardProps) { return title }\nfunction helper(props: OtherProps) { return props }\n' > "$repo/Good.tsx"
run_hook "$repo/Good.tsx"
[ "$status" -eq 0 ] || fail "correct component flagged: $output"

# A repository opts out of my rules in .gh44.json
printf '{ "rulesOff": ["brain/component-props-name", "@typescript-eslint/consistent-type-assertions"] }\n' > "$repo/.gh44.json"
printf 'interface Props { title: string }\nexport function Card(props: Props) { return props as unknown }\n' > "$repo/OptOut.tsx"
run_hook "$repo/OptOut.tsx"
[ "$status" -eq 0 ] || fail "rulesOff must turn off my rules: $output"

# Naming, effects, params, hook results, index files and folders
new_repo
expect_rule() {
  run_hook "$1"
  echo "$output" | grep -q "$2" || fail "$2 not reported for $(basename "$1"): $(cat "$1") -> $output"
}
expect_clean() {
  run_hook "$1"
  [ "$status" -eq 0 ] || fail "$(basename "$1") should pass: $(cat "$1") -> $output"
}
w() { mkdir -p "$(dirname "$repo/$1")"; printf '%s\n' "$2" > "$repo/$1"; echo "$repo/$1"; }

expect_rule "$(w Handler.tsx 'export function Form({ save }: FormProps) { const submit = () => save(); return <button onClick={submit} /> }')" brain/handler-names
expect_clean "$(w HandlerOk.tsx 'export function HandlerOk({ onClose, store }: HandlerOkProps) { const handleSubmit = () => onClose(); return <><button onClick={handleSubmit} /><a onClick={onClose} /><i onClick={() => onClose()} /><b onClick={store.add} /></> }')"

expect_rule "$(w flags.ts 'export const open = true')" brain/boolean-names
expect_rule "$(w compare.ts 'export const same = 1 === 2')" brain/boolean-names
expect_rule "$(w types.ts 'export interface Options { disabled: boolean }')" brain/boolean-names
expect_clean "$(w flagsOk.ts 'export const isOpen = true
export interface OptionsOk { hasMore: boolean; shouldRetry?: boolean }')"

expect_rule "$(w Effect.tsx 'import { useEffect } from "react"
export function Effect() { useEffect(() => {}, []); return null }')" brain/no-use-effect
expect_rule "$(w EffectReact.tsx 'import React from "react"
export function EffectReact() { React.useLayoutEffect(() => {}); return null }')" brain/no-use-effect

expect_rule "$(w params.ts 'export function join(first: string, second: string) { return first + second }')" brain/params-object
expect_rule "$(w arrow.ts 'export const sum = (left: number, right: number) => left + right')" brain/params-object
expect_clean "$(w paramsOk.ts 'export function join({ first, second }: JoinParams) { return [first, second].map((item, index) => item + index).reduce((total, item) => total + item, "") }')"

expect_rule "$(w Store.tsx 'export function Store() { const { add } = useUserStore(); return add }')" brain/no-hook-destructure
expect_clean "$(w StoreOk.tsx 'export function StoreOk() { const userStore = useUserStore(); const [count, setCount] = useState(0); userStore.add(count); return setCount }')"

expect_rule "$(w Card/index.ts 'export const size = 1')" brain/index-reexport-only
expect_clean "$(w CardOk/index.ts 'export { Card } from "./Card"
export * from "./utils"
export type { CardProps } from "./types"
export { default } from "./Card"')"

expect_rule "$(w src/shared/format.ts 'export const pad = 1')" brain/no-generic-folders
expect_rule "$(w src/lib/format.ts 'export const pad = 1')" brain/no-generic-folders
expect_clean "$(w src/utils/format.ts 'export const pad = 1')"

# JSX: nested ternaries, index keys, leaked renders
expect_rule "$(w Ternary.tsx 'export function Ternary({ status }: TernaryProps) { return <div>{status === "a" ? <A /> : status === "b" ? <B /> : null}</div> }')" brain/no-jsx-nested-ternary
expect_rule "$(w TernaryReturn.tsx 'export function TernaryReturn({ isA, isB }: TernaryReturnProps) { return isA ? <A /> : isB ? <B /> : null }')" brain/no-jsx-nested-ternary
expect_clean "$(w TernaryOk.tsx 'export function TernaryOk({ isA }: TernaryOkProps) { const size = isA ? 1 : isA === false ? 2 : 3; return <div>{isA ? <A size={size} /> : null}</div> }')"

expect_rule "$(w IndexKey.tsx 'export function IndexKey({ items }: IndexKeyProps) { return items.map((item, index) => <li key={index}>{item.name}</li>) }')" brain/no-index-key
expect_rule "$(w IndexKeyTemplate.tsx 'export function IndexKeyTemplate({ items }: IndexKeyTemplateProps) { return items.map((item, i) => <li key={`row-${i}`}>{item.name}</li>) }')" brain/no-index-key
expect_clean "$(w IndexKeyOk.tsx 'export function IndexKeyOk({ items }: IndexKeyOkProps) { return items.map((item, index) => <li key={item.id}>{index}</li>) }')"

expect_rule "$(w Leaked.tsx 'export function Leaked({ items }: LeakedProps) { return <ul>{items.length && <li />}</ul> }')" brain/no-leaked-render
expect_rule "$(w LeakedCount.tsx 'export function LeakedCount({ count }: LeakedCountProps) { return <ul>{count && <li />}</ul> }')" brain/no-leaked-render
expect_clean "$(w LeakedOk.tsx 'export function LeakedOk({ items, isOpen, user }: LeakedOkProps) { return <ul title={user && user.name}>{isOpen && <li />}{items.length > 0 && <li />}{!!user && <li />}{user?.isAdmin && isOpen && <li />}{Boolean(user) && <li />}{IS_FF_X_ENABLED && <li />}{items.length ? <li /> : null}</ul> }')"

echo "PASS lint"
