// My personal ESLint rules. hooks/check-code.sh runs them on every file Claude edits.
// Fixable rules are fixed silently; the rest are sent back to Claude.
// A rule the repository already configures is turned off, so the repository wins.
import eslintReact from "@eslint-react/eslint-plugin";
import perfectionist from "eslint-plugin-perfectionist";
import testingLibrary from "eslint-plugin-testing-library";
import tseslint from "typescript-eslint";

import brain from "./rules/index.js";

// Add rules here. Severity 'error' blocks Claude until fixed; 'off' disables a rule.
const myRules = {
  "perfectionist/sort-imports": [
    "error",
    {
      type: "natural",
      groups: ["builtin", "external", "internal", ["parent", "sibling", "index"], "unknown"],
      newlinesBetween: 1,
    },
  ],
  "@typescript-eslint/no-explicit-any": "error",
  "@typescript-eslint/consistent-type-assertions": ["error", { assertionStyle: "never" }],
  "brain/no-lint-disable": "error",
  "brain/boolean-names": "error",
  "brain/params-object": "error",
  "brain/no-hook-destructure": "error",
  "brain/no-use-effect": "error",
  "brain/index-reexport-only": "error",
  "brain/no-generic-folders": "error",
  "brain/no-enum": "error",
  "brain/props-only-interface": "error",
  "@eslint-react/rules-of-hooks": "error",
  "@eslint-react/no-unnecessary-use-prefix": "error",
  "@eslint-react/use-state": "error",
  "@eslint-react/naming-convention-ref-name": "error",
  "@eslint-react/naming-convention-id-name": "error",
  "@eslint-react/naming-convention-context-name": "error",
  "no-console": ["error", { allow: ["error", "warn"] }],
  "no-empty": ["error", { allowEmptyCatch: false }],
};

// Rules for test files only.
const myTestRules = {
  "testing-library/prefer-user-event": "error",
  "testing-library/prefer-screen-queries": "error",
  "testing-library/no-container": "error",
  "testing-library/no-node-access": "error",
};

// Rules for React component files only.
const myComponentRules = {
  "@eslint-react/no-class-component": "error",
  "brain/component-props-name": "error",
  "brain/handler-names": "error",
  "brain/no-jsx-nested-ternary": "error",
  "@eslint-react/no-array-index-key": "error",
  "@eslint-react/no-missing-key": "error",
  "@eslint-react/no-duplicate-key": "error",
  "@eslint-react/jsx-no-key-after-spread": "error",
  "@eslint-react/no-nested-component-definitions": "error",
  "@eslint-react/purity": "error",
  "@eslint-react/set-state-in-render": "error",
  "@eslint-react/jsx-no-useless-fragment": "error",
  "@eslint-react/jsx-no-comment-textnodes": "error",
  "@eslint-react/jsx-no-leaked-dollar": "error",
  "@eslint-react/jsx-no-leaked-semicolon": "error",
  "@eslint-react/dom-no-script-url": "error",
  "@eslint-react/dom-no-unsafe-target-blank": "error",
  "@eslint-react/dom-no-void-elements-with-children": "error",
  "brain/no-leaked-render": "error",
};

// Other names for the same concern. If the repository configures any of them, my rule is
// turned off. `formatter:sort-imports` means the repository's formatter sorts imports.
export const equivalents = {
  "perfectionist/sort-imports": [
    "formatter:sort-imports",
    "sort-imports",
    "import/order",
    "simple-import-sort/imports",
  ],
  "@eslint-react/no-class-component": [
    "react/prefer-stateless-function",
    "react/prefer-function-component",
  ],
  "@eslint-react/rules-of-hooks": ["react-hooks/rules-of-hooks"],
  "@eslint-react/purity": ["react-hooks/purity"],
  "@eslint-react/set-state-in-render": ["react-hooks/set-state-in-render"],
  "@eslint-react/no-nested-component-definitions": [
    "react/no-unstable-nested-components",
    "react-hooks/static-components",
  ],
  "@eslint-react/no-missing-key": ["react/jsx-key"],
  "@eslint-react/jsx-no-useless-fragment": ["react/jsx-no-useless-fragment"],
  "@eslint-react/jsx-no-comment-textnodes": ["react/jsx-no-comment-textnodes"],
  "@eslint-react/dom-no-script-url": ["react/jsx-no-script-url"],
  "@eslint-react/dom-no-unsafe-target-blank": ["react/jsx-no-target-blank"],
  "@eslint-react/dom-no-void-elements-with-children": ["react/void-dom-elements-no-children"],
  "brain/no-jsx-nested-ternary": ["no-nested-ternary", "unicorn/no-nested-ternary"],
  "@eslint-react/no-array-index-key": ["react/no-array-index-key"],
  "brain/no-leaked-render": [
    "react/jsx-no-leaked-render",
    "@eslint-react/no-leaked-conditional-rendering",
  ],
  "brain/props-only-interface": ["@typescript-eslint/consistent-type-definitions"],
};

// Older @eslint-react versions name the same rules `react-x/no-missing-key`,
// `@eslint-react/dom/no-script-url` or `react-dom/no-script-url`.
for (const rule of Object.keys({ ...myRules, ...myComponentRules })) {
  if (!rule.startsWith("@eslint-react/")) continue;
  const name = rule.slice("@eslint-react/".length);
  const [, group, rest] = name.match(/^(dom|web-api|naming-convention|jsx)-(.+)$/) ?? [];
  const aliases = [`react-x/${name}`];
  if (group) aliases.push(`@eslint-react/${group}/${rest}`, `react-${group}/${rest}`);
  if (group === "jsx") aliases.push(`@eslint-react/${rest}`, `react-x/${rest}`);
  equivalents[rule] = [...(equivalents[rule] ?? []), ...aliases];
}

const plugins = {
  "@typescript-eslint": tseslint.plugin,
  brain,
  perfectionist,
  "@eslint-react": eslintReact,
  "testing-library": testingLibrary,
};

export default [
  {
    files: ["**/*.{ts,tsx,mts,cts}"],
    languageOptions: { parser: tseslint.parser },
    plugins,
    linterOptions: { noInlineConfig: true },
    rules: myRules,
  },
  {
    files: ["**/*.tsx"],
    rules: myComponentRules,
  },
  {
    files: ["**/*.{test,spec}.{ts,tsx}"],
    rules: myTestRules,
  },
  {
    files: ["**/utils/**/*.{ts,tsx}"],
    ignores: ["**/*.{test,spec}.{ts,tsx}"],
    rules: { "brain/pure-utils": "error" },
  },
];
