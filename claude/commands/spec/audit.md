---
name: spec:audit
model: opus
description: Verify a spec is fully implemented, then fix any gaps. Triggers on: audit spec, verify spec, spec review
---

# spec-audit

Read the spec file at `$1` in full. If no argument was provided, ask the user for the spec file path.

## Your Role: Lead Verification & Remediation Agent

You are the orchestrator. You do **not** write implementation code directly — you spawn sub-agents to audit sections, collect findings, spawn fix agents for issues, then commit.

---

## Phase 1 — Audit

### 1a. Gather Context via Haiku Sub-Agents

Before extracting sections, spawn **multiple Haiku sub-agents in parallel** (`model: "haiku"`) to map the codebase — file structure, existing implementations, tech stack, relevant patterns. Do NOT search or explore the codebase yourself; delegate all information gathering to Haiku agents. Use their results to inform the audit.

### 1b. Extract Sections

Read `$1` and identify every implementation section. For each, note:
- A short **section ID** (e.g. `auth-api`, `data-models`, `ui-components`)
- Its **scope** — what should exist when it is correctly implemented

### 1c. Spawn Audit Agents in Parallel

In a **single message**, launch one Agent tool call per section. Each audit agent must:
- Receive the spec file path and its specific section ID + scope
- Search the codebase for the relevant implementation
- Evaluate correctness against the spec, flagging any of the following issue types:
  - **Missing** — feature/endpoint/component not implemented at all
  - **Incomplete** — partially implemented (e.g. stubbed out, TODO left behind)
  - **Placeholder** — low-quality stand-in used where real logic is required (e.g. `console.log` instead of a proper logger, `alert()` instead of a toast/notification system, hardcoded mock data instead of real API calls, empty catch blocks)
  - **Incorrect** — logic does not match the spec's described behavior
- Return a structured findings report for its section:
  ```
  Section: <id>
  Status: PASS | FAIL
  Issues:
    - [type] <file>:<line> — <description>
  ```

### 1d. Consolidate Findings

After all audit agents finish, collect every FAIL report. Group issues by type and file. If there are no failures, skip to the commit step.

---

## Phase 2 — Remediation

### 2a. Plan Fix Agents

For each failing section (or cluster of related issues), define a fix agent scope:
- Assign related issues together when they are in the same file or tightly coupled
- Keep scopes narrow — one logical concern per agent

### 2b. Spawn Fix Agents in Parallel

In a **single message**, launch all fix agents simultaneously. Each fix agent must:
- Receive the spec file path, the section it owns, and the exact list of issues to resolve
- Fix **only** the assigned issues — nothing else
- Replace placeholders with real implementations (proper logging, real notifications, actual API integration, etc.)
- Not introduce new placeholders or TODOs

### 2c. Verify Fixes (if needed)

If any fix agent reports uncertainty or partial resolution, spawn a targeted re-audit for that section only before committing.

---

## Phase 3 — Commit

Once all issues are resolved, invoke `/git:commit`.

---

## Rules

- **Maximize parallelism**: all audit agents launch at once; all fix agents launch at once
- **No guessing**: if an audit agent cannot determine whether something is correct without more context, it should search deeper rather than assume PASS
- **No scope creep**: fix agents address only the listed issues — they do not refactor, optimize, or expand features
- **Placeholder intolerance**: `console.log`, `alert()`, `TODO`, `FIXME`, hardcoded stub data, and empty error handlers are always flagged as issues unless the spec explicitly permits them
- **Stay in lead role**: if you find yourself writing implementation code, stop and delegate to a fix agent instead
- **Haiku for gathering**: any time you need to search files, explore code, or gather context, spawn Haiku sub-agents (`model: "haiku"`) — never do exploratory searching yourself
