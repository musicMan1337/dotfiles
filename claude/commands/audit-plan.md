---
name: audit-plan
description: Audit generated/changed code against the plan it was built from, via the plan-auditor agent. Maps every plan item to diff evidence and reports completeness (implemented/partial/missing), drift, and surface bug/security risks. Run after implementing a plan (PLAN.md, PLAN_<slug>.md, spec, case description), especially when other agents wrote the code. Triggers on, audit plan, audit the plan, check plan against code, plan audit, did we implement the plan, verify plan completeness, audit generated code, /audit-plan.
---

# /audit-plan

Spawn the `plan-auditor` agent (read-only, Opus-pinned) on a plan artifact + diff scope, then relay its report. This skill orchestrates; the agent does all reading. Do not pre-read the plan or the diff into the main session.

## Step 1: Resolve inputs

**Plan artifact.** From `$ARGUMENTS` if a path or pasted text was given. Otherwise auto-detect, in order:

1. `PLAN_*.md` or `PLAN.md` in cwd (worktree/spec convention)
2. `.claude/plans/*.md` matching the current branch's case id

Exactly one match: use it silently. Multiple or zero: ask which (numbered options; zero-match options are "paste the plan" or "audit diff-only without a plan", the latter degrades to drift+risk lenses only).

**Diff scope.** From args if given (a ref, branch, or file list). Otherwise default to `<default-branch merge-base>...HEAD`. If the working tree is dirty, include uncommitted changes in the scope and note it.

## Step 2: Spawn the agent

One `plan-auditor` agent (Agent tool, `subagent_type: "plan-auditor"`), foreground. Prompt must contain: the plan path (or pasted plan text verbatim), the diff scope (exact refs), the repo root, and any scope notes from the user (e.g. "frontend only", "ignore test files"). Do not spawn more than one; the agent aggregates internally (AV-safe I/O).

## Step 3: Relay and route

Relay the report intact: coverage table (missing/contradicts rows first), drift, risks, runtime-only questions. Do not soften verdicts, do not fix anything.

Then offer next steps (numbered):

1. Fix the missing/contradicts items
2. Deep security pass (spawn `security-auditor` on the flagged files) — only offer when the report has `defer: security-auditor` rows
3. Run /verify on the runtime-only questions
4. Done

## Gotchas

- **Auditor is read-only and independent by design.** Never let the session that wrote the code also edit the report; the value is the fresh set of eyes.
- **One agent, not a fan-out.** All lenses live in the single plan-auditor pass (CryptoGuard).
- **No plan means degraded mode, not a fake plan.** Never synthesize a plan from the diff and then "audit" against it; that just grades the diff against itself.
