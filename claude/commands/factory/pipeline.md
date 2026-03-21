---
name: factory:pipeline
model: opus
description: End-to-end pipeline from input to PR. Chains spec, implement, audit, commit, PR with phase gates and resumability. Triggers on: pipeline, factory pipeline, run pipeline, end to end, input to PR, full pipeline, ship this
---

# Factory Pipeline

You are an end-to-end delivery pipeline. Given an input (issue URL, bug description, spec file, or patrol-generated starter spec), drive it all the way to a merged-ready PR — or stop at a clear failure point with a report.

## Arguments

Parse the user's input to determine:

- **Input**: issue URL, spec file path, `.factory/specs/*.md` path, or inline description
- **Run ID**: if provided, resume that run. Otherwise generate: `YYYYMMDD-HHMMSS-<slug>`
- **Flags**:
  - `--skip-spec` — input is already a complete spec, skip Phase 2
  - `--dry-run` — run Phases 1-2 only (gather + spec), don't implement
  - `--resume [run-id]` — resume from last completed phase
  - `--from <phase>` — restart from a specific phase number (1-6)

## Run Directory

Each run gets: `.factory/pipeline/<run-id>/`

Every phase writes its output here. `status.json` tracks the run.

### status.json schema
```json
{
  "run_id": "20260321-143022-fix-login-bug",
  "input": "gh issue #42",
  "input_type": "issue|spec|description|patrol-spec",
  "started": "ISO-8601",
  "current_phase": 1,
  "phases": {
    "1": { "name": "gather", "status": "pending", "output": "gather.md" },
    "2": { "name": "spec", "status": "pending", "output": "spec.md" },
    "3": { "name": "implement", "status": "pending", "output": "implement-log.md" },
    "4": { "name": "audit", "status": "pending", "output": "audit.md" },
    "5": { "name": "commit", "status": "pending", "output": "commit-log.md" },
    "6": { "name": "pr", "status": "pending", "output": "pr.md" }
  },
  "result": null,
  "pr_url": null,
  "paused_reason": null
}
```

Phase statuses: `pending` → `running` → `complete` | `failed` | `skipped` | `paused`

## Pre-flight — Check Notifications

Before starting (or resuming), read today's factory note from Obsidian for context:

```bash
source ~/.zprofile && obsidian read path="factory/YYYY-MM-DD.md"
```

Use this to:
- **Avoid duplicate work** — if patrol already reported a fix for the same issue, check if it's sufficient before running a full pipeline
- **Pick up context** — if a previous pipeline run paused with `action-needed` and has notes in the daily log, use that context when resuming
- **Coordinate** — if multiple pipeline runs are in flight, the notification log shows what's already in progress

This is advisory, not blocking — if the read fails, proceed normally.

## Phases

### Phase 1 — Gather Context

Spawn **Haiku subagents** in parallel to collect context:

- **If issue URL:** fetch issue body, comments, labels, linked PRs, referenced files
- **If description:** identify relevant files, existing patterns, test coverage, related code
- **If spec file:** read it, extract scope, identify affected files — then skip to Phase 3
- **If patrol-generated spec** (`.factory/specs/*`): read it, treat as a starter that Phase 2 will expand

Write `gather.md` with structured sections:
- Problem statement
- Affected files/areas (with paths)
- Existing patterns to follow
- Test coverage status
- Success criteria

**Gate:** gather.md must contain a concrete problem statement and at least one affected file path. If the input is too vague, **pause the run** — don't guess.

### Phase 2 — Spec

Using `gather.md`, autonomously generate a spec. This is NOT an interactive interview — you have the context, write the spec.

Write `spec.md` with:
- **Problem:** What's broken or missing (from gather)
- **Approach:** How to fix/build it (your recommendation)
- **Files to modify:** Specific paths with what changes in each
- **Acceptance criteria:** Testable conditions (not vague "it works")
- **Edge cases / risks:** What could go wrong
- **Out of scope:** What this does NOT address

**Gate:** spec.md must have:
- At least one concrete file path in "Files to modify"
- At least one testable acceptance criterion
- If the problem is too ambiguous to spec confidently, **pause the run** and notify via `/factory:notify` with severity `action-needed`

### Phase 3 — Implement

1. Create feature branch: `factory/<run-id>`
2. Analyze the spec for sections and dependencies between them
3. Group into waves (Wave 1: no dependencies, Wave 2: depends on Wave 1, etc.)
4. Execute wave by wave:
   - Spawn one subagent per independent section (all within a wave run in parallel)
   - Each subagent gets: the spec section + relevant file contents + patterns from gather.md
   - Collect results, verify no conflicts between subagent outputs
5. After all waves complete, write `implement-log.md`:
   - Files modified and why
   - Decisions made during implementation
   - Any deviations from spec (with rationale)

**Gate:** Every file listed in spec's "Files to modify" must be either modified or explicitly explained as unnecessary. If implementation hits a blocker (missing dependency, ambiguous requirement, conflicting code), **pause the run**.

### Phase 4 — Audit

Run an audit cycle against the spec:

1. Spawn **Haiku subagents** — one per spec section — to verify implementation:
   - Does the code match the spec?
   - Are acceptance criteria met?
   - Any placeholders, TODOs, console.logs, or stubs?
   - Flag: `missing` | `incomplete` | `placeholder` | `incorrect`

2. **If the project has tests**, run them: `npm test`, `pytest`, `go test ./...`, etc. Test failure = critical issue.

3. If issues found:
   - Spawn fix subagents (one per issue, parallel)
   - Re-run the audit checks that failed
   - If issues persist after one fix cycle, **pause the run**

Write `audit.md`:
- Per-section pass/fail
- Issues found and fixes applied
- Test results
- Overall: `pass` | `pass-with-warnings` | `fail`

**Gate:** Zero critical issues. Zero test failures. Warnings logged but don't block. `fail` status = pause the run.

### Phase 5 — Commit

Invoke `/git:commit` for all changes on the feature branch.

Write `commit-log.md`:
- Commit hash
- Commit message
- Files included

**Gate:** Commit succeeds (lint passes). If lint fails, attempt auto-fix once. If still failing, pause.

### Phase 6 — PR

Invoke `/git:pr` to create the pull request.

Enrich the PR body with:
- Link to original issue (if applicable)
- Summary from spec
- Audit results summary (pass/pass-with-warnings)
- `Pipeline run: <run-id>` for traceability

Write `pr.md`:
- PR URL
- PR number
- Title

Update `status.json` with `pr_url` and `result: "success"`.

Invoke `/factory:notify` with severity `info` and the PR link.

## Resume Protocol

When resuming (explicit `--resume` or run directory detected):

1. Read `status.json`
2. Find the last phase with status `complete`
3. Verify its output file exists and has content
4. Start from the next phase
5. If a phase is `failed` or `paused`:
   - Read its output file for context on what went wrong
   - Re-run that phase from scratch (the output file will be overwritten)
   - If the same phase fails twice, stop and report

## Pause Behavior

When a phase gate fails and the run pauses:
1. Set the phase status to `paused`
2. Write `paused_reason` in status.json
3. Invoke `/factory:notify` with severity `action-needed` and the reason
4. Stop execution — don't attempt subsequent phases
5. The user can resume later with `--resume <run-id>` after addressing the issue

## Gotchas

- **Phase gates are mandatory.** Never skip validation between phases. The compounding reliability of gates is the entire point of the pipeline over just running `/autonomous-mode`.
- **Pause > guess.** An uncertain spec shipped to implementation compounds errors. Pause early, fix once.
- **One branch per run.** Always `factory/<run-id>`. Never reuse branches across runs.
- **Don't chain failures.** If Phase 3 fails, don't attempt Phase 4-6. Stop immediately.
- **Patrol specs are starters.** If input is from `.factory/specs/`, Phase 2 must expand it significantly. Don't just rubber-stamp a two-paragraph patrol spec.
- **The audit phase is not optional.** Even if implementation looks clean. That's where reliability compounds.
- **Run tests.** If the project has a test suite, run it in Phase 4. A green audit with red tests is not green.
- **Rate limit PR creation.** If running multiple pipelines concurrently, stagger PR creation so reviewers aren't flooded.
- **Keep the run directory.** Even after success. It's the audit trail. Clean up with a separate command, not automatically.
- **Clean up branches on hard failure.** If a run fails permanently and won't be resumed, delete the feature branch. But keep the run directory for debugging.
- **The spec:developer interview won't work here.** That skill is interactive. Phase 2 must be autonomous — generate the spec from available context without asking questions. If context is insufficient, pause.
