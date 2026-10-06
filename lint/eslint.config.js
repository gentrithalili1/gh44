// My personal ESLint rules. hooks/check-code.sh runs them on every file Claude edits.
// Fixable rules are fixed silently; the rest are sent back to Claude.
// A rule the repository already configures is turned off, so the repository wins.
import perfectionist from 'eslint-plugin-perfectionist'
import tseslint from 'typescript-eslint'

import brain from './rules/index.js'

// Add rules here. Severity 'error' blocks Claude until fixed; 'off' disables a rule.
const myRules = {
  'perfectionist/sort-imports': [
    'error',
    {
      type: 'natural',
      groups: [
        'builtin',
        'external',
        'internal',
        ['parent', 'sibling', 'index'],
        'unknown',
      ],
      newlinesBetween: 1,
    },
  ],
  '@typescript-eslint/no-explicit-any': 'error',
}

// Rules for React component files only.
const myComponentRules = {
  'brain/no-class-component': 'error',
  'brain/component-props-name': 'error',
}

// Other names for the same concern. If the repository configures any of them, my rule is
// turned off. `formatter:sort-imports` means the repository's formatter sorts imports.
export const equivalents = {
  'perfectionist/sort-imports': [
    'formatter:sort-imports',
    'sort-imports',
    'import/order',
    'simple-import-sort/imports',
  ],
  'brain/no-class-component': [
    'react/prefer-stateless-function',
    'react/prefer-function-component',
    'react-x/no-class-component',
    '@eslint-react/no-class-component',
  ],
}

const plugins = { '@typescript-eslint': tseslint.plugin, brain, perfectionist }

export default [
  {
    files: ['**/*.{ts,tsx,mts,cts}'],
    languageOptions: { parser: tseslint.parser },
    plugins,
    linterOptions: { noInlineConfig: true },
    rules: myRules,
  },
  {
    files: ['**/*.tsx'],
    rules: myComponentRules,
  },
]
