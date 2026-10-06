// My own ESLint rules, for conventions no published plugin covers.
const isPascalCase = (name) => /^[A-Z][A-Za-z0-9]*$/.test(name);

const propsTypeName = (param) => {
  const annotation = param?.typeAnnotation?.typeAnnotation;
  if (annotation?.type !== "TSTypeReference" || annotation.typeName.type !== "Identifier") {
    return;
  }
  return annotation.typeName.name;
};

const componentPropsName = {
  meta: {
    type: "suggestion",
    docs: {
      description: "Name a component props interface after the component: `CardProps` for `Card`.",
    },
    messages: {
      rename: "Name the props interface of `{{component}}` `{{expected}}`, not `{{actual}}`.",
    },
    schema: [],
  },
  create(context) {
    const check = (name, fn, node) => {
      if (!name || !isPascalCase(name)) {
        return;
      }
      const actual = propsTypeName(fn.params[0]);
      const expected = `${name}Props`;
      if (!actual || !actual.endsWith("Props") || actual === expected) {
        return;
      }
      context.report({
        node,
        messageId: "rename",
        data: { component: name, expected, actual },
      });
    };
    return {
      FunctionDeclaration(node) {
        check(node.id?.name, node, node);
      },
      VariableDeclarator(node) {
        const init = node.init;
        if (init?.type !== "ArrowFunctionExpression" && init?.type !== "FunctionExpression") {
          return;
        }
        if (node.id.type === "Identifier") {
          check(node.id.name, init, node);
        }
      },
    };
  },
};

const noClassComponent = {
  meta: {
    type: "suggestion",
    docs: { description: "Write components as functions, not classes." },
    messages: { useFunction: "Write `{{component}}` as a function component." },
    schema: [],
  },
  create(context) {
    const isReactBase = (superClass) => {
      if (superClass?.type === "Identifier") {
        return /^(Pure)?Component$/.test(superClass.name);
      }
      return (
        superClass?.type === "MemberExpression" &&
        superClass.object.name === "React" &&
        /^(Pure)?Component$/.test(superClass.property.name)
      );
    };
    const check = (node) => {
      if (!isReactBase(node.superClass)) {
        return;
      }
      context.report({
        node,
        messageId: "useFunction",
        data: { component: node.id?.name ?? "this class" },
      });
    };
    return { ClassDeclaration: check, ClassExpression: check };
  },
};

const noLintDisable = {
  meta: {
    type: "problem",
    docs: { description: "Fix the code instead of disabling a lint rule." },
    messages: { fix: "Fix the code instead of disabling the lint rule." },
    schema: [],
  },
  create(context) {
    return {
      Program() {
        for (const comment of context.sourceCode.getAllComments()) {
          if (/(eslint|oxlint)-disable/.test(comment.value))
            context.report({ loc: comment.loc, messageId: "fix" });
        }
      },
    };
  },
};

const pureUtils = {
  meta: {
    type: "problem",
    docs: { description: "Files in utils/ stay pure: no React, i18n or Sentry." },
    messages: {
      pure: "Files in utils/ stay pure. Move `{{source}}` code into a hook or component.",
    },
    schema: [],
  },
  create(context) {
    return {
      ImportDeclaration(node) {
        const source = node.source.value;
        if (/^(react|react-dom|react-intl|@sentry\/.+)$/.test(source)) {
          context.report({ node, messageId: "pure", data: { source } });
        }
      },
    };
  },
};

const isCallbackArgument = (node) =>
  (node.parent?.type === "CallExpression" || node.parent?.type === "NewExpression") &&
  node.parent.arguments.includes(node);

const handlerNames = {
  meta: {
    type: "suggestion",
    docs: { description: "Name event handlers `handle*`." },
    messages: { rename: "Name the handler passed to `{{prop}}` `handle*`, not `{{name}}`." },
    schema: [],
  },
  create(context) {
    return {
      JSXAttribute(node) {
        if (node.name.type !== "JSXIdentifier" || !/^on[A-Z]/.test(node.name.name)) return;
        const expression =
          node.value?.type === "JSXExpressionContainer" ? node.value.expression : null;
        if (expression?.type !== "Identifier") return;
        if (/^(handle|on)[A-Z]/.test(expression.name)) return;
        context.report({
          node,
          messageId: "rename",
          data: { prop: node.name.name, name: expression.name },
        });
      },
    };
  },
};

const booleanPrefix = /^(is|has|should|can|did|will|was|are)[A-Z]/;

const isBooleanExpression = (node) =>
  (node?.type === "Literal" && typeof node.value === "boolean") ||
  (node?.type === "UnaryExpression" && node.operator === "!") ||
  (node?.type === "BinaryExpression" &&
    /^(===|!==|==|!=|<|>|<=|>=|in|instanceof)$/.test(node.operator));

const booleanNames = {
  meta: {
    type: "suggestion",
    docs: { description: "Name booleans `is*`, `has*` or `should*`." },
    messages: {
      rename:
        "Name the boolean `{{name}}` with `is`, `has` or `should`, for example `is{{suffix}}`.",
    },
    schema: [],
  },
  create(context) {
    const report = (node, name) => {
      if (booleanPrefix.test(name)) return;
      context.report({
        node,
        messageId: "rename",
        data: { name, suffix: name[0].toUpperCase() + name.slice(1) },
      });
    };
    const isBooleanType = (annotation) => annotation?.typeAnnotation?.type === "TSBooleanKeyword";
    return {
      VariableDeclarator(node) {
        if (node.id.type !== "Identifier") return;
        if (isBooleanType(node.id.typeAnnotation) || isBooleanExpression(node.init))
          report(node.id, node.id.name);
      },
      TSPropertySignature(node) {
        if (node.key.type === "Identifier" && isBooleanType(node.typeAnnotation))
          report(node.key, node.key.name);
      },
    };
  },
};

const noUseEffect = {
  meta: {
    type: "suggestion",
    docs: { description: "Avoid effects." },
    messages: {
      avoid:
        "Avoid `{{name}}`: derive the value during render, act in an event handler, or fetch with a data hook. If it is really needed, tell the user why.",
    },
    schema: [],
  },
  create(context) {
    return {
      CallExpression(node) {
        const callee = node.callee;
        const name =
          callee.type === "Identifier"
            ? callee.name
            : callee.type === "MemberExpression" && callee.property.type === "Identifier"
              ? callee.property.name
              : null;
        if (name === "useEffect" || name === "useLayoutEffect")
          context.report({ node, messageId: "avoid", data: { name } });
      },
    };
  },
};

const paramsObject = {
  meta: {
    type: "suggestion",
    docs: { description: "Functions with 2 or more parameters take one params object." },
    messages: { object: "Take one params object instead of {{count}} parameters." },
    schema: [],
  },
  create(context) {
    const check = (node) => {
      if (node.params.length < 2) return;
      if (isCallbackArgument(node) || node.parent?.type === "JSXExpressionContainer") return;
      context.report({ node, messageId: "object", data: { count: node.params.length } });
    };
    return {
      FunctionDeclaration: check,
      FunctionExpression: check,
      ArrowFunctionExpression: check,
    };
  },
};

const noHookDestructure = {
  meta: {
    type: "suggestion",
    docs: { description: "Keep a hook result whole instead of destructuring it." },
    messages: {
      whole:
        "Keep the result of `{{hook}}()` whole, for example `const {{name}} = {{hook}}()`, then use `{{name}}.<member>`.",
    },
    schema: [],
  },
  create(context) {
    return {
      VariableDeclarator(node) {
        if (node.id.type !== "ObjectPattern" || node.init?.type !== "CallExpression") return;
        const callee = node.init.callee;
        if (callee.type !== "Identifier" || !/^use[A-Z]/.test(callee.name)) return;
        const name = callee.name[3].toLowerCase() + callee.name.slice(4);
        context.report({ node, messageId: "whole", data: { hook: callee.name, name } });
      },
    };
  },
};

const indexReexportOnly = {
  meta: {
    type: "suggestion",
    docs: { description: "`index.ts` only re-exports." },
    messages: { reexport: "`index.ts` only re-exports. Move this code into its own file." },
    schema: [],
  },
  create(context) {
    if (!/(^|\/)index\.tsx?$/.test(context.filename)) return {};
    const isReexport = (statement) =>
      (statement.type === "ExportNamedDeclaration" && statement.source) ||
      statement.type === "ExportAllDeclaration";
    return {
      Program(node) {
        for (const statement of node.body) {
          if (!isReexport(statement)) context.report({ node: statement, messageId: "reexport" });
        }
      },
    };
  },
};

const noGenericFolders = {
  meta: {
    type: "suggestion",
    docs: { description: "No generic buckets such as lib/, shared/, store/ or features/." },
    messages: {
      folder: "Do not put files in a `{{folder}}/` folder. Place the file by its importers.",
    },
    schema: [],
  },
  create(context) {
    const folder = context.filename.match(/\/(lib|shared|store|features)\//)?.[1];
    if (!folder) return {};
    return {
      Program(node) {
        context.report({
          loc: { line: 1, column: 0 },
          node,
          messageId: "folder",
          data: { folder },
        });
      },
    };
  },
};

export default {
  meta: { name: "agent-brain" },
  rules: {
    "component-props-name": componentPropsName,
    "no-class-component": noClassComponent,
    "no-lint-disable": noLintDisable,
    "pure-utils": pureUtils,
    "handler-names": handlerNames,
    "boolean-names": booleanNames,
    "no-use-effect": noUseEffect,
    "params-object": paramsObject,
    "no-hook-destructure": noHookDestructure,
    "index-reexport-only": indexReexportOnly,
    "no-generic-folders": noGenericFolders,
  },
};
