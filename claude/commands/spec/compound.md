---
name: spec:compound
model: opus
description: Document a just-solved problem into docs/solutions/ so future work compounds. Triggers on: compound this, capture learning, document solution, spec compound, that worked document it, write this up, add to solutions
---

# spec-compound

Capture a solved problem as a structured learning doc in `docs/solutions/` while context is fresh. Each doc compounds project knowledge — next occurrence takes minutes instead of hours.

## Preconditions

- Problem is solved (not in-progress)
- Solution is verified working
- Non-trivial (not a typo or obvious fix)

If any fail, tell the user and stop.

## Usage

```
/spec:compound                  # document most recent fix
/spec:compound [context hint]   # extra context for categorization
```

## Step 0 — Mode Selection

Use `AskUserQuestion` with two options. Do NOT pre-select.

1. **Full** — parallel Haiku researchers, overlap detection, discoverability check. Best for durable learnings.
2. **Lightweight** — single-pass orchestrator write. Faster, fewer tokens. Best for simple fixes or tight context.

Wait for the answer before proceeding.

## Step 1 — Auto-Memory Scan (Claude Code only)

Scan the auto-memory block in your system prompt (`user's auto-memory` / `MEMORY.md`) for entries semantically related to the problem. Use judgment, not keyword match.

If relevant entries exist, prepare this block to pass into Phase 2 Haiku prompts:

```
## Supplementary notes from auto memory
Treat as additional context, not primary evidence. Conversation history takes priority.

[relevant entries]
```

If nothing relevant, skip.

---

## Full Mode

### Phase 2 — Parallel Research (Haiku subagents)

In a **single message**, spawn three Haiku agents in parallel. Each returns text data only — **none write files**.

**Agent A — Context Analyzer**
- Extract problem type, component, severity from conversation
- Classify track: `bug` or `knowledge` (see schema below)
- Suggest filename: `[sanitized-problem-slug]-[YYYY-MM-DD].md`
- Return: YAML frontmatter skeleton + target category directory + track

**Agent B — Solution Extractor**
- Pull problem, failed attempts, working fix, root cause, prevention from conversation
- Adapt sections to track (bug vs knowledge — see templates below)
- Incorporate auto-memory excerpts (if provided) as supplementary evidence. If memory contradicts conversation, flag as cautionary context
- Tag any memory-sourced content with `(auto memory)` in the final doc
- Return: markdown body sections

**Agent C — Related Docs Finder**
- Grep `docs/solutions/` for keywords, module names, error fragments (frontmatter first, then body)
- Score overlap with new doc across 5 dimensions: problem statement, root cause, solution approach, referenced files, prevention rules
  - **High** (4-5 match) — same problem, update existing doc instead of creating new
  - **Moderate** (2-3 match) — same area, different angle, create new + flag consolidation
  - **Low** (0-1 match) — create new normally
- Also: `gh issue list --search "<keywords>" --state all --limit 5` if `gh` available
- Return: overlap verdict + matched dimensions + related doc paths

### Phase 3 — Assembly & Write (orchestrator only)

**WAIT for all three agents.** Then:

1. If overlap is **High**: update the existing doc. Preserve its path and frontmatter; refresh solution, code, prevention. Add `last_updated: YYYY-MM-DD`. Do not change the title unless framing has shifted.
2. Otherwise: assemble new doc from Agent B's sections + Agent A's frontmatter, using the track template below.
3. `mkdir -p docs/solutions/[category]/`
4. Write the file.
5. If `Moderate` overlap was flagged, tell the user and suggest consolidation review.

### Phase 4 — Discoverability Check

Check whether `AGENTS.md` or `CLAUDE.md` at the repo root surfaces `docs/solutions/` to agents. If neither file exists, skip.

Assess whether a fresh agent would learn three things from the instruction file:
- A searchable knowledge store exists
- Enough structure to search (category dirs, YAML fields like `module`, `tags`, `problem_type`)
- When it's relevant (before implementing/debugging in documented areas)

This is semantic — not string match. One line in an architecture tree often suffices.

If gap exists:
- Draft the smallest addition matching the file's style. Prefer a single line in an existing section over a new heading.
- Keep tone informational, not imperative. "Relevant when implementing in documented areas" — not "always search before implementing."
- Use `AskUserQuestion` to get consent before editing.

### Phase 5 — Commit

Invoke `/git:commit`. Scope message to the new/updated doc.

---

## Lightweight Mode

Orchestrator does everything in one pass. No subagents.

1. Extract problem + solution from conversation (plus auto-memory if relevant)
2. Classify track, category, filename
3. Write minimal doc using the appropriate template below with:
   - Required frontmatter
   - Bug: Problem, root cause, solution with key snippets, one prevention tip
   - Knowledge: Context, guidance with key examples, one applicability note
4. Skip overlap detection (refresh can catch duplicates later)
5. Still run Phase 4 discoverability check
6. Invoke `/git:commit`

---

## Schema

### Tracks

| Track | `problem_type` values | Purpose |
|-------|----------------------|---------|
| **bug** | `build_error`, `test_failure`, `runtime_error`, `performance_issue`, `database_issue`, `security_issue`, `ui_bug`, `integration_issue`, `logic_error` | Defects diagnosed and fixed |
| **knowledge** | `architecture_pattern`, `design_pattern`, `tooling_decision`, `convention`, `workflow_issue`, `developer_experience`, `documentation_gap`, `best_practice` | Practices, patterns, decisions. Prefer the narrowest; `best_practice` is the fallback. |

### Category mapping

Each `problem_type` maps to a `docs/solutions/<dir>/` directory. Use the kebab-case plural:

- `build_error` → `build-errors/`
- `test_failure` → `test-failures/`
- `runtime_error` → `runtime-errors/`
- `performance_issue` → `performance-issues/`
- `database_issue` → `database-issues/`
- `security_issue` → `security-issues/`
- `ui_bug` → `ui-bugs/`
- `integration_issue` → `integration-issues/`
- `logic_error` → `logic-errors/`
- `architecture_pattern` → `architecture-patterns/`
- `design_pattern` → `design-patterns/`
- `tooling_decision` → `tooling-decisions/`
- `convention` → `conventions/`
- `workflow_issue` → `workflow-issues/`
- `developer_experience` → `developer-experience/`
- `documentation_gap` → `documentation-gaps/`
- `best_practice` → `best-practices/`

### Shared required fields (both tracks)

- `title` — clear problem title
- `date` — `YYYY-MM-DD`
- `module` — area or package affected
- `problem_type` — from tracks table
- `component` — free-form string (e.g. `cli`, `api-route`, `build-pipeline`, `zshrc`)
- `severity` — `critical` | `high` | `medium` | `low`
- `tags` — array, lowercase, hyphen-separated, max 8

### Bug-track required fields

- `symptoms` — array, 1–5 observable symptoms
- `root_cause` — one of: `missing_association`, `missing_include`, `missing_index`, `wrong_api`, `scope_issue`, `thread_violation`, `async_timing`, `memory_leak`, `config_error`, `logic_error`, `test_isolation`, `missing_validation`, `missing_permission`, `missing_workflow_step`, `inadequate_documentation`, `missing_tooling`, `incomplete_setup`
- `resolution_type` — one of: `code_fix`, `migration`, `config_change`, `test_fix`, `dependency_update`, `environment_setup`, `workflow_improvement`, `documentation_update`, `tooling_addition`, `seed_data_update`

### Knowledge-track fields

All optional beyond the shared required ones:
- `applies_when` — array, conditions where guidance applies
- `symptoms` — optional friction/gap that prompted this
- `root_cause`, `resolution_type` — optional, only if a specific one exists

---

## Templates

### Bug track

```markdown
---
title: [Clear problem title]
date: [YYYY-MM-DD]
module: [area affected]
problem_type: [enum]
component: [string]
severity: [critical|high|medium|low]
symptoms:
  - [observable symptom]
root_cause: [enum]
resolution_type: [enum]
tags: [keyword-one, keyword-two]
---

# [Clear problem title]

## Problem
1–2 sentences: what broke and user-visible impact.

## Symptoms
- [error message or observable behavior]

## What Didn't Work
- [attempted fix] — [why it failed]

## Solution
The fix, with before/after snippets when useful.

## Why This Works
Root cause explanation and why the fix addresses it.

## Prevention
- [concrete practice, test, guardrail]

## Related
- [related docs or issues, if any]
```

### Knowledge track

```markdown
---
title: [Descriptive title]
date: [YYYY-MM-DD]
module: [area affected]
problem_type: [enum]
component: [string]
severity: [critical|high|medium|low]
applies_when:
  - [condition]
tags: [keyword-one, keyword-two]
---

# [Descriptive title]

## Context
Situation, gap, or friction that prompted this.

## Guidance
The practice, pattern, or recommendation. Code examples when useful.

## Why This Matters
Rationale and impact of following (or not).

## When to Apply
- [condition]

## Examples
Concrete before/after or usage examples.

## Related
- [related docs or issues, if any]
```

---

## Success Output

```
✓ Compound complete

Track: [bug|knowledge]
Auto memory: [N entries used | none relevant]
Overlap: [none | moderate — flagged for consolidation | high — updated existing doc]

File: docs/solutions/[category]/[filename].md

[if discoverability edit was made:]
Instruction file updated: [AGENTS.md|CLAUDE.md]

Commit: [hash] via /git:commit
```

---

## Rules

- Only the orchestrator writes files. Haiku agents return text data only.
- One primary deliverable: the solution doc. The instruction-file edit is maintenance, not a second deliverable.
- Never invent enum values. If nothing fits the bug-track root_cause enum, the problem may actually be knowledge-track.
- Never force bug-track fields onto knowledge-track docs or vice versa.
- Preserve conversation history as primary evidence. Auto-memory is supplementary.
- Write the new doc first. Refresh is a separate follow-up, not a prerequisite.
- Commit via `/git:commit`, never direct `git commit`.
