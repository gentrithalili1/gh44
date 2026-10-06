// Lints one file with my ESLint config, fixing what can be fixed in place.
// Rules the repository already owns are turned off first, so the repository wins.
// Prints the remaining errors as JSON: [{ line, ruleId, message }].
import { execFileSync } from 'node:child_process'
import { existsSync, readFileSync, readdirSync, realpathSync } from 'node:fs'
import { createRequire } from 'node:module'
import path from 'node:path'
import { pathToFileURL } from 'node:url'

import { ESLint } from 'eslint'

import config, { equivalents } from './eslint.config.js'

const configFile = path.join(import.meta.dirname, 'eslint.config.js')

const findRepoRoot = (directory) => {
  try {
    return execFileSync(
      'git',
      ['-C', directory, 'rev-parse', '--show-toplevel'],
      {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore'],
      }
    ).trim()
  } catch {
    return directory
  }
}

const readJson = (file) => {
  try {
    return JSON.parse(readFileSync(file, 'utf8'))
  } catch {
    return
  }
}

// oxlint writes `eslint/curly` and `typescript/no-explicit-any`; ESLint writes `curly`
// and `@typescript-eslint/no-explicit-any`.
const normalize = (rule) =>
  rule.replace(/^eslint\//, '').replace(/^typescript\//, '@typescript-eslint/')

const collectOxlintRules = (file, owned, seen = new Set()) => {
  if (seen.has(file)) {
    return
  }
  seen.add(file)
  const oxlint = readJson(file)
  if (!oxlint) {
    return
  }
  const rulesBlocks = [
    oxlint.rules,
    ...(oxlint.overrides ?? []).map((override) => override.rules),
  ]
  for (const rules of rulesBlocks) {
    for (const rule of Object.keys(rules ?? {})) {
      owned.add(normalize(rule))
    }
  }
  for (const parent of oxlint.extends ?? []) {
    collectOxlintRules(path.resolve(path.dirname(file), parent), owned, seen)
  }
}

const formatterSortsImports = (repoRoot) => {
  const oxfmt = readJson(path.join(repoRoot, '.oxfmtrc.json'))
  if (oxfmt?.sortImports || oxfmt?.experimentalSortImports) {
    return true
  }
  const biome = readJson(path.join(repoRoot, 'biome.json'))
  if (
    biome?.organizeImports?.enabled ||
    biome?.assist?.actions?.source?.organizeImports
  ) {
    return true
  }
  const prettierFiles = readdirSync(repoRoot).filter((name) =>
    name.startsWith('.prettierrc')
  )
  const prettierSources = [
    ...prettierFiles.map((name) =>
      readFileSync(path.join(repoRoot, name), 'utf8')
    ),
    JSON.stringify(
      readJson(path.join(repoRoot, 'package.json'))?.prettier ?? ''
    ),
  ]
  return prettierSources.some((source) =>
    /sort-imports|organize-imports/.test(source)
  )
}

const repoEslintRules = async (repoRoot, file) => {
  const hasConfig = readdirSync(repoRoot).some((name) =>
    /^(eslint\.config\.|\.eslintrc)/.test(name)
  )
  if (!hasConfig) {
    return []
  }
  try {
    const require = createRequire(path.join(repoRoot, 'package.json'))
    const { ESLint: RepoESLint } = await import(
      pathToFileURL(require.resolve('eslint')).href
    )
    const repoConfig = await new RepoESLint({
      cwd: repoRoot,
    }).calculateConfigForFile(file)
    return Object.keys(repoConfig?.rules ?? {})
  } catch {
    return []
  }
}

const ownedRules = async (repoRoot, file) => {
  const owned = new Set(await repoEslintRules(repoRoot, file))
  for (
    let directory = path.dirname(file);
    ;
    directory = path.dirname(directory)
  ) {
    collectOxlintRules(path.join(directory, '.oxlintrc.json'), owned)
    if (directory === repoRoot || directory === path.dirname(directory)) {
      break
    }
  }
  if (formatterSortsImports(repoRoot)) {
    owned.add('formatter:sort-imports')
  }
  return owned
}

if (!existsSync(process.argv[2])) {
  process.exit(0)
}
// Real path, so a symlinked path such as /var -> /private/var stays inside the repo root.
const file = realpathSync(process.argv[2])
const repoRoot = findRepoRoot(path.dirname(file))
const owned = await ownedRules(repoRoot, file)

const myRuleNames = config.flatMap((block) => Object.keys(block.rules ?? {}))
// A repository can also opt out explicitly in .agent-brain.json: { "rulesOff": ["rule-id"] }.
const rulesOff = new Set(
  readJson(path.join(repoRoot, '.agent-brain.json'))?.rulesOff ?? []
)
const disabled = myRuleNames.filter(
  (rule) =>
    rulesOff.has(rule) ||
    [rule, ...(equivalents[rule] ?? [])].some((name) => owned.has(name))
)

const eslint = new ESLint({
  cwd: repoRoot,
  overrideConfigFile: configFile,
  overrideConfig: {
    rules: Object.fromEntries(disabled.map((rule) => [rule, 'off'])),
  },
  fix: true,
  errorOnUnmatchedPattern: false,
  warnIgnored: false,
})
const results = await eslint.lintFiles([file])
await ESLint.outputFixes(results)

const errors = results
  .flatMap((result) => result.messages)
  .filter((message) => message.severity === 2 && message.ruleId)
  .map(({ line, ruleId, message }) => ({ line, ruleId, message }))
process.stdout.write(JSON.stringify(errors))
