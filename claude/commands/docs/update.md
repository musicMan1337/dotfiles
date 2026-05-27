---
name: docs:update
model: opus
description: Update local repo agent-target docs (CLAUDE.md, SKILL.md, READMEs, plans/specs) with lessons, conventions, or style changes from the current conversation. Triggers on, update docs, update claude md, capture lesson, update repo docs, refresh agent docs, document this convention, update readme for agents, update plan, update spec, docs update.
allowed-tools: Read, Edit, Write, Bash, Glob, Grep, Agent
---

# Docs Update

Sync agent-targeted documentation in the current repo with what was actually done, decided, or learned in this conversation. Only edit docs that future agents (or future-you starting fresh) would benefit from.

## Input

**Request:** $ARGUMENTS

- No args → infer scope from current conversation
- A scope hint ("just CLAUDE.md", "skip READMEs", "focus on the auth refactor", "include the new SQL convention") → narrow or expand the candidate set accordingly
- A specific file path → update only that file (still using current-context signal)

## What counts as an agent-target doc

In priority order:

1. **`CLAUDE.md`** at repo root or anywhere in the tree — direct instructions to Claude in this repo
2. **`SKILL.md`** files under `.claude/`, `commands/`, or any skill folder
3. **`AGENTS.md`, `.claude/rules/*.md`, `.cursorrules`, `.windsurfrules`** — sibling agent-rule files
4. **`README.md`** at repo root — but ONLY the "conventions", "architecture", "gotchas", or "how to work in this repo" sections; skip generic install/usage prose
5. **Plans and specs** the conversation explicitly worked from: `.planning/**/PLAN.md`, `.planning/**/SPEC.md`, `docs/specs/*.md`, `docs/decisions/*.md`, `docs/adr/*.md`
6. **Component-local docs** that read like agent guidance: any `README.md` inside a package that documents conventions, patterns, or gotchas

Do NOT touch user-facing docs (changelogs, public API reference, install guides, marketing copy) unless the user explicitly requests it.

## Step 1 — Inventory candidate docs

Run a parallel discovery pass (use a Haiku subagent to keep this cheap):

```
fd -t f -e md . | rg -i '(CLAUDE|AGENTS|SKILL|README|\.cursorrules|\.windsurfrules|PLAN|SPEC|ADR)' | head -100
ls .claude/rules/ 2>/dev/null
ls .planning/ 2>/dev/null
```

For each candidate, capture: path, top heading, last-modified date. Show this list to the user only if it's >10 files or ambiguous; otherwise proceed silently.

## Step 2 — Extract update-worthy signal from the conversation

Scan the current conversation for:

- **Decisions made** ("we decided to X because Y")
- **Conventions used** that aren't already documented (naming patterns, file placement, import paths)
- **Gotchas hit** ("this failed because X" → future agents need to know)
- **Standards changed** (new lint rule, new test convention, framework upgrade)
- **Pattern shifts** ("we now use X instead of Y for this case")
- **Newly added repo skills, scripts, or commands** that need a pointer
- **Stale or contradicted statements** in existing docs — these need removal, not addition

Filter ruthlessly:
- A bug fix is NOT doc-worthy. Only the *lesson* from the bug fix is.
- "Renamed function X" is NOT doc-worthy. "Renaming convention shifted to X-style" IS.
- One-off task details (this PR's scope, this commit's files) are NEVER doc-worthy.
- If a future agent would read the doc and shrug, the update is dead weight — cut it.

## Step 3 — Match signal to file

For each piece of signal, pick the single most appropriate target file. Mental model:

- "Future agents working in this repo need this" → `CLAUDE.md`
- "Future agents using this specific skill need this" → that skill's `SKILL.md`
- "This is a decision with rationale future-us may forget" → ADR or `docs/decisions/`
- "This is part of a planned phase's contract" → that phase's `PLAN.md` / `SPEC.md`
- "This is a component-internal convention" → that component's `README.md`

If a signal doesn't fit cleanly, prefer NOT adding it over adding it in the wrong place.

## Step 4 — Draft a focused diff

For each target file, produce a minimal patch:

- Prefer **editing an existing section** over adding a new one
- Match the file's existing voice and density (CLAUDE.md is terse, plans/specs are more detailed)
- For CLAUDE.md additions: one line each, lead with the rule, follow with the why only if non-obvious
- Use `Edit` (not `Write`) so the diff is auditable
- If removing stale content, show it explicitly in the diff preview

Group all proposed diffs and present them to the user:

```
Proposed updates:

1. CLAUDE.md (root)
   + "When adding internal workspace imports, declare in package.json deps (Vite externalizes only declared deps)."
   - removed: stale reference to ESLint 8 (we're on 9 now)

2. .claude/rules/symlink-new-files.md
   + clarify that scripts under language-configs/ also need symlinks

3. .planning/current-milestone/PHASE-3/PLAN.md
   + note: AuthMiddleware now uses #[RequiresPermission] attribute, not #[Controlled]
```

## Step 5 — Get approval, then write

Hard gate: never write without the user picking. Present numbered options:

1. Approve all
2. Approve some — user lists which numbers
3. Make changes (user describes adjustments)
4. Skip

Only after approval, apply edits. If multiple files change, batch the edits in parallel where they're independent.

## Step 6 — Report

One-line summary per file touched. Done.

## Gotchas

- **Don't restate the obvious.** "Use TypeScript" in a TypeScript repo is dead weight. Only encode what would surprise a competent new contributor.
- **Don't document one-off task details.** "Fixed the auth bug in PR #123" belongs in the PR description and git history, not CLAUDE.md. The lesson from the fix might be doc-worthy; the fix itself never is.
- **CLAUDE.md stays terse.** If you're about to add a multi-paragraph section, that's a sign it belongs in a referenced doc, not CLAUDE.md. CLAUDE.md should read like a punch list of rules.
- **Stale content is invisible damage.** A wrong statement in CLAUDE.md is worse than a missing one — it actively misleads future agents. When you notice contradicted content, propose removal alongside additions.
- **Resist the urge to "comprehensively document" everything done.** This skill is for capturing lessons that shift future behavior, not for writing a project journal. If you're proposing >5 updates from one conversation, you're probably over-fitting to the current task.
- **Plans/specs are append-only mid-phase.** If a phase is in flight, don't rewrite its plan — add a "Deviations" or "Notes" section instead. The original plan is the contract.
- **Project-level conventions, not personal preferences.** "I prefer 2-space indent" is not doc-worthy. "This repo uses 2-space indent for JS, 4 for Python" only matters if it diverges from tooling defaults.
- **When the conversation produced no doc-worthy signal, say so and stop.** Forcing updates to justify the invocation produces noise. A clean "nothing to update" is a valid outcome.
