// My own ESLint rules, for conventions no published plugin covers.
const isPascalCase = (name) => /^[A-Z][A-Za-z0-9]*$/.test(name)

const propsTypeName = (param) => {
  const annotation = param?.typeAnnotation?.typeAnnotation
  if (
    annotation?.type !== 'TSTypeReference' ||
    annotation.typeName.type !== 'Identifier'
  ) {
    return
  }
  return annotation.typeName.name
}

const componentPropsName = {
  meta: {
    type: 'suggestion',
    docs: {
      description:
        'Name a component props interface after the component: `CardProps` for `Card`.',
    },
    messages: {
      rename:
        'Name the props interface of `{{component}}` `{{expected}}`, not `{{actual}}`.',
    },
    schema: [],
  },
  create(context) {
    const check = (name, fn, node) => {
      if (!name || !isPascalCase(name)) {
        return
      }
      const actual = propsTypeName(fn.params[0])
      const expected = `${name}Props`
      if (!actual || !actual.endsWith('Props') || actual === expected) {
        return
      }
      context.report({
        node,
        messageId: 'rename',
        data: { component: name, expected, actual },
      })
    }
    return {
      FunctionDeclaration(node) {
        check(node.id?.name, node, node)
      },
      VariableDeclarator(node) {
        const init = node.init
        if (
          init?.type !== 'ArrowFunctionExpression' &&
          init?.type !== 'FunctionExpression'
        ) {
          return
        }
        if (node.id.type === 'Identifier') {
          check(node.id.name, init, node)
        }
      },
    }
  },
}

const noClassComponent = {
  meta: {
    type: 'suggestion',
    docs: { description: 'Write components as functions, not classes.' },
    messages: { useFunction: 'Write `{{component}}` as a function component.' },
    schema: [],
  },
  create(context) {
    const isReactBase = (superClass) => {
      if (superClass?.type === 'Identifier') {
        return /^(Pure)?Component$/.test(superClass.name)
      }
      return (
        superClass?.type === 'MemberExpression' &&
        superClass.object.name === 'React' &&
        /^(Pure)?Component$/.test(superClass.property.name)
      )
    }
    const check = (node) => {
      if (!isReactBase(node.superClass)) {
        return
      }
      context.report({
        node,
        messageId: 'useFunction',
        data: { component: node.id?.name ?? 'this class' },
      })
    }
    return { ClassDeclaration: check, ClassExpression: check }
  },
}

const noLintDisable = {
  meta: {
    type: 'problem',
    docs: { description: 'Fix the code instead of disabling a lint rule.' },
    messages: { fix: 'Fix the code instead of disabling the lint rule.' },
    schema: [],
  },
  create(context) {
    return {
      Program() {
        for (const comment of context.sourceCode.getAllComments()) {
          if (/(eslint|oxlint)-disable/.test(comment.value)) context.report({ loc: comment.loc, messageId: 'fix' })
        }
      },
    }
  },
}

const pureUtils = {
  meta: {
    type: 'problem',
    docs: { description: 'Files in utils/ stay pure: no React, i18n or Sentry.' },
    messages: { pure: 'Files in utils/ stay pure. Move `{{source}}` code into a hook or component.' },
    schema: [],
  },
  create(context) {
    return {
      ImportDeclaration(node) {
        const source = node.source.value
        if (/^(react|react-dom|react-intl|@sentry\/.+)$/.test(source)) {
          context.report({ node, messageId: 'pure', data: { source } })
        }
      },
    }
  },
}

export default {
  meta: { name: 'agent-brain' },
  rules: {
    'component-props-name': componentPropsName,
    'no-class-component': noClassComponent,
    'no-lint-disable': noLintDisable,
    'pure-utils': pureUtils,
  },
}
