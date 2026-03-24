---
name: linting:setup-node
model: opus
description: Set up ESLint, Prettier, and strict TypeScript config for a Node/React/Next.js repo. Triggers on: setup linting, add eslint, configure prettier, lint setup, setup node linting, add linting to project
---

# Linting Setup — Node/TypeScript

You are setting up a modern, strict linting and formatting configuration for a Node.js/TypeScript project. Your goal is to produce a production-grade config that enforces consistency and catches real bugs.

## Process

### Phase 1 — Detect the Stack

Spawn a **Haiku sub-agent** to analyze the repo and report:
- Package manager (npm, yarn, pnpm, bun) — check for lock files
- Framework (React, Next.js, Vue, Nuxt, Svelte, Express, Fastify, plain Node, etc.)
- TypeScript version and whether `tsconfig.json` exists
- Existing linting setup (any eslint/prettier configs, `.eslintrc.*`, `eslint.config.*`, `.prettierrc.*`)
- Test framework (Jest, Vitest, Mocha, Playwright, etc.)
- Module system (ESM vs CJS) — check `"type"` in package.json
- Monorepo structure (workspaces, turborepo, nx)

### Phase 2 — Research Current Best Practices

Spawn **WebSearch sub-agents** in parallel to get the latest guidance for each detected component:
1. "ESLint 9 flat config setup [detected-framework] 2025" — get the latest flat config patterns
2. "prettier eslint integration 2025 eslint-config-prettier" — current integration approach
3. "[detected-framework] eslint recommended plugins 2025" — framework-specific plugins
4. If TypeScript: "typescript-eslint v8 strict config 2025" — latest strict TS linting

Use the research results to inform your config choices. Prefer official/recommended configs from each tool's documentation.

### Phase 3 — Install Packages

Install the appropriate packages based on detected stack. Always use the project's package manager with `--save-dev`.

**Core (always):**
- `eslint` (latest v9+)
- `prettier`
- `eslint-config-prettier` (disables ESLint rules that conflict with Prettier)

**TypeScript (if detected):**
- `typescript-eslint` (the unified package for v8+)
- `@types/node` if not already present

**Framework-specific (examples — adapt based on research):**
- React: `eslint-plugin-react`, `eslint-plugin-react-hooks`, `eslint-plugin-jsx-a11y`
- Next.js: `@next/eslint-plugin-next` (or use `eslint-config-next` which bundles plugins)
- Vue: `eslint-plugin-vue`
- Node/Express: `eslint-plugin-n`
- Testing: `eslint-plugin-testing-library`, `eslint-plugin-jest`, `eslint-plugin-vitest` as appropriate

### Phase 4 — Create Configs

#### ESLint — `eslint.config.mjs` (flat config)

Create a modern ESLint 9+ flat config. Structure:

```js
// eslint.config.mjs
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import prettierConfig from "eslint-config-prettier";
// ... framework-specific imports

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  // framework configs...
  prettierConfig, // MUST be last to override conflicting rules
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    ignores: ["dist/", "build/", "node_modules/", ".next/", "coverage/"],
  },
  {
    // Custom rule overrides — only where the strict defaults are genuinely wrong
    rules: {
      // Add framework-appropriate overrides here
    },
  }
);
```

Key points:
- Use `tseslint.configs.strictTypeChecked` (NOT just `strict` — we want type-aware rules)
- Use `tseslint.configs.stylisticTypeChecked` for consistent style
- `eslint-config-prettier` MUST be the last config to properly disable conflicting rules
- Use `projectService: true` for type-aware linting (the modern approach)

#### Prettier — `.prettierrc`

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "arrowParens": "always",
  "endOfLine": "lf",
  "bracketSpacing": true
}
```

Create `.prettierignore` with sensible defaults (dist, build, node_modules, coverage, lock files).

#### TypeScript — `tsconfig.json` Strictness

If a `tsconfig.json` exists, ensure these strict options are enabled. If it doesn't exist, create one.

**Maximum strictness settings:**
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

When modifying an existing tsconfig:
- **Preserve** existing `target`, `module`, `moduleResolution`, `jsx`, `paths`, `outDir`, `rootDir`, `baseUrl`, `lib`, `types`, and framework-specific settings
- **Add** strict flags that are missing
- If the tsconfig extends a framework config (e.g., `@next/tsconfig`), only add flags that aren't already covered by the base

### Phase 5 — Add npm Scripts

Add these scripts to `package.json`:

```json
{
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix && prettier --write ."
  }
}
```

If scripts named `lint` or `lint:fix` already exist, update them rather than creating duplicates. Preserve other existing scripts.

### Phase 6 — Validate

Run `npm run lint` (or the project's package manager equivalent). If there are:

1. **Configuration errors or plugin compatibility issues:** This is critical — DO NOT just remove the problematic config. Instead:
   - Read the error message carefully
   - Spawn a **WebSearch sub-agent** to search for the exact error message + the package versions involved
   - Apply the fix from the search results
   - Only if no fix exists after searching should you downgrade or remove a config, and explain why to the user

2. **Linting errors in existing code:** This is expected and fine — report the count to the user but don't auto-fix unless asked. Mention they can run `npm run lint:fix` to auto-fix what's possible.

## Gotchas

- **ESLint 9 flat config is mandatory.** The old `.eslintrc.*` format is deprecated. If the project has legacy configs, migrate them to `eslint.config.mjs`. Remove old config files after migration.
- **`eslint-config-prettier` must be LAST** in the config array. If it's not last, Prettier-conflicting rules from later configs will re-enable and cause lint/format wars.
- **`typescript-eslint` v8 uses a unified package.** Don't install the old `@typescript-eslint/parser` + `@typescript-eslint/eslint-plugin` separately — they're bundled in `typescript-eslint` now.
- **`projectService: true` replaces the old `project` option.** Don't use `project: './tsconfig.json'` — that's the legacy approach. `projectService` is faster and handles multi-tsconfig setups automatically.
- **`exactOptionalPropertyTypes`** can be aggressive — it differentiates between `undefined` and "missing". Some libraries don't type this correctly. If it causes widespread issues with third-party types, it's the ONE strict flag that's acceptable to disable after searching for fixes first.
- **Next.js has its own ESLint config** (`eslint-config-next`). Layer the strict TypeScript rules ON TOP of it rather than replacing it, since it includes Next.js-specific rules for things like Image, Link, etc.
- **Monorepo setups** may need a root eslint config that references individual tsconfigs per package. Use `projectService` which handles this automatically in most cases.
- **Don't forget `.prettierignore`** — without it, Prettier will try to format files in `dist/`, `build/`, lock files, etc., which is slow and produces noise.
- **`verbatimModuleSyntax`** replaces the old `importsNotUsedAsValues` and `preserveValueImports`. If those old flags exist in tsconfig, remove them when adding `verbatimModuleSyntax`.
- **Some frameworks (e.g., Vite, SvelteKit) use `"type": "module"` in package.json.** This is why we use `eslint.config.mjs` (explicit ESM) — it works regardless of the module system setting.
