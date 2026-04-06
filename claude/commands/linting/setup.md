---
name: linting:setup
model: opus
description: Set up the strictest possible linting, formatting, and type checking for the current repo with pre-commit hooks. Triggers on: setup linting, add linting, strict linting, configure prettier, configure eslint, add formatting, setup pre-commit hooks, enforce code style, add type checking, lint this repo, strict types
allowed-tools: Agent, Bash, Read, Write, Edit, Glob, Grep, Skill
---

You are setting up the **strictest possible** linting, formatting, and type-checking configuration for this repository, plus automatic pre-commit hooks to enforce it all.

## Phase 1 — Detect the Codebase

Before doing anything, understand what you're working with. Read the project root to identify:

- **Languages** (check file extensions, config files like `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `.csproj`/`.sln`, `Gemfile`, `composer.json`, etc.)
- **Existing linting/formatting** (any `.eslintrc*`, `.prettierrc*`, `biome.json`, `ruff.toml`, `.editorconfig`, `rustfmt.toml`, `.clang-format`, `tslint.json`, `stylua.toml`, etc.)
- **Existing pre-commit setup** (`.husky/`, `.pre-commit-config.yaml`, `.git/hooks/`, `lefthook.yml`, `lint-staged` in package.json)
- **Package manager** (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm, `bun.lockb` → bun)
- **Monorepo structure** (workspaces, multiple packages)
- **TypeScript config** (`tsconfig.json` — check current strictness level)
- **CI configuration** (`.github/workflows/`, `.gitlab-ci.yml`, etc. — useful context for what's already enforced)

## Phase 2 — Research Modern Best Practices

**CRITICAL: Spawn Haiku subagents for ALL research. Do not search directly.** Launch these in parallel:

### Subagent 1 — Linting & Formatting Tools
Research the most modern, actively maintained linting and formatting tools for the detected language(s). Focus on:
- What tools are currently recommended by the community (not deprecated/abandoned)
- Which tools can replace multiple older ones (e.g., Biome replacing ESLint+Prettier for JS/TS)
- Strictest rule sets and preset configs available
- Compatibility with the project's runtime/framework versions

### Subagent 2 — Type Checking Strictness
Research the strictest possible type-checking configuration for the detected language(s). Examples:
- **TypeScript**: Every `strict` family flag, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noPropertyAccessFromIndexType`, `verbatimModuleSyntax`, etc.
- **Python**: `mypy --strict` or `pyright` strict mode, `py.typed` markers
- **Rust**: Strict clippy lints, `#![deny(warnings)]`
- **Go**: `staticcheck`, `golangci-lint` with aggressive config
- **C#**: `<TreatWarningsAsErrors>`, nullable reference types, StyleCop/Roslynator analyzers

### Subagent 3 — Pre-Commit Hook Setup
Research the best way to set up automatic pre-commit hooks for this stack:
- **Node/JS/TS**: Husky + lint-staged (or lefthook as alternative)
- **Python**: pre-commit framework
- **Rust**: cargo-husky or custom git hooks
- **Multi-language**: pre-commit framework (works for any language)
- How to ensure hooks run on staged files only (not the whole repo)
- How to make hooks fast (parallel execution, incremental checking)

## Phase 3 — Implement

Based on research findings, implement everything. Follow these principles:

1. **Strictest defaults, then relax only if something breaks.** Start with the most aggressive config. If a rule causes false positives on existing code, note it but still enable it — the user can decide what to relax.

2. **Layer tools correctly.** Don't have overlapping responsibilities:
   - Formatting tool handles all style (indentation, quotes, semicolons, line width)
   - Linter handles logic and correctness (unused vars, unsafe patterns, import order)
   - Type checker handles type safety
   - Pre-commit hooks run all of the above on staged files

3. **Install packages** using the detected package manager. Use exact versions, not ranges.

4. **Create config files** with inline comments explaining non-obvious choices, especially where you chose the stricter option over the default.

5. **Set up pre-commit hooks** that:
   - Run formatting (auto-fix) on staged files
   - Run linting (with --fix where safe) on staged files
   - Run type checking
   - Fail fast — stop on first error category that fails
   - Are fast — only check staged/changed files, not the whole repo

6. **Add npm scripts / Makefile targets / task runner commands** so developers can run checks manually too (e.g., `lint`, `format`, `typecheck`, `lint:fix`).

7. **Handle existing code violations gracefully.** If the codebase has many existing violations:
   - Still configure the strict rules
   - Run the auto-fixers to clean up what can be auto-fixed
   - For remaining violations, inform the user of the count and let them decide whether to fix now or suppress temporarily

## Phase 4 — Verify

After implementation:
1. Run the formatter and confirm it works
2. Run the linter and confirm it reports/fixes issues
3. Run the type checker and confirm it works
4. Test the pre-commit hook by staging a file and checking that hooks fire
5. Report a summary: what was installed, what configs were created, how many existing violations were found

## Gotchas

- **Don't blindly install Biome over ESLint.** Biome doesn't support all ESLint plugins (e.g., react-hooks, jsx-a11y). Check plugin compatibility first. If the project relies on framework-specific ESLint plugins, keep ESLint for linting and use a separate formatter.
- **TypeScript `strict: true` is NOT the strictest.** It's a bundle of flags but doesn't include `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, or several other strict flags added later. Always enumerate and enable individual strict flags beyond the `strict` umbrella.
- **Husky v9+ changed setup significantly.** The `husky install` pattern is outdated — modern Husky uses a `prepare` script and `.husky/` directory differently. Research the current version's setup.
- **lint-staged must match the formatter's file patterns.** Mismatched globs between lint-staged and the formatter config cause files to slip through.
- **Don't run type-checking on staged files only** — TypeScript/mypy need the full project context. Run `tsc --noEmit` or `mypy .` on the whole project in the pre-commit hook, not just staged files.
- **Monorepos need per-package or root-level config.** Don't assume a single config works — check if workspaces need individual configs.
- **Python projects: prefer `ruff` over `flake8`+`isort`+`black` individually.** Ruff replaces all three and is dramatically faster. But verify it supports the project's Python version.
- **Pre-commit hooks should be idempotent.** Running them twice should produce the same result. Formatters that re-stage files can cause infinite loops if not configured correctly.

## Operational Constraints

- **ALL research MUST go through Haiku subagents.** Do not use Glob, Grep, or web search tools directly for research. Only use direct tools for reading specific known files during implementation.
- **Commit via `/git:commit`** when done — never commit directly.
- After implementation, ask the user if they want to commit the changes.
