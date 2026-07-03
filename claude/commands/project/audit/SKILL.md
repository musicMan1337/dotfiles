---
name: project:audit
model: opus
description: >
  Audit an EXISTING project against the agent-dev-first pillars and supply-chain + linting hardening,
  then fix gaps with your approval. Checks: can an agent boot it functionally AND visually in
  isolation (CLI-first, no Playwright bias), are tests red-green (a green-only suite is a finding),
  does the database/deps run locally, and are packages + lint tooling locked and hardened. Produces a
  scored gap report; applies fixes per approved batch. Triggers on: audit project, audit my repo,
  audit this project, check project setup, is my stack agent-ready, project health, project:audit.
---

# /project:audit — audit an existing project against the pillars

Run the same pipeline as `/project:new`, but against a repo that already exists: **diff** the current
state against the three pillars and the supply-chain/linting hardening expectations, present gaps as a
scored report, and apply fixes **per approved batch** (your chosen mode).

**Read both shared refs before acting:**
- [`../_refs/pillars.md`](../_refs/pillars.md) — the three pillars you're auditing against.
- [`../_refs/orchestration.md`](../_refs/orchestration.md) — the staged flow; you run the **AUDIT**
  path (see the `AUDIT:` notes per stage).

You are the orchestrator (opus). Delegate discovery and any lookups to Haiku subagents; invoke
`/setup:package-lockdown` and `/setup:linting` in their **existing-project (audit)** mode rather than
reimplementing them. Existing stack choices stay unless they fail a pillar.

## What you do

1. **Stage 0 — Detect.** Discover the project (languages, frameworks, package managers, lockfile
   state, test setup, lint/format config, datastore wiring). Decide its shape; declare which pillars
   apply. No project-name prompt, no autonomous prototype build.
2. **Score against the pillars + hardening** (Stages 1–4, audit framing):
   - **Pillar 1:** is there an agent-runnable functional path AND a visual path, CLI-first?
   - **Pillar 2:** are tests red-green, or is this a green-only suite (a finding)?
   - **Pillar 3:** does it boot locally with a stubbed datastore/deps, no cloud creds?
   - **Hardening:** are packages locked + hardened? Is lint/format/typecheck + hooks present and strict?
3. **Report + apply.** Present findings as **numbered items** grouped by pillar/area, each with
   severity and a proposed fix. Apply fixes in batches; **get approval before each batch.** Re-run the
   Stage 3 reconciliation loop if lint/package changes introduce conflicts.

## Gotchas

- **Audit, don't rebuild.** Don't replace a working stack because it isn't your default. Only flag a
  choice when it genuinely fails an applicable pillar; otherwise harden what's there.
- **Green-only suite = finding, not pass.** The most common false-pass: tests that have only ever been
  green. Flag the absence of a demonstrated red path; spot-check by proposing a red flip.
- **A "visual test" that's really one tool doing double duty is a gap.** Pillar 1 wants *two
  independent paths* (functional + visual). One Playwright suite covering both is not two paths.
- **CLI-first.** If the only agent control surface is a GUI or a heavy MCP broker where a CLI would do,
  that's a finding worth raising even if "it works."
- **Hosted-only DB is a finding.** If the project can't boot without cloud credentials, the local-first
  pillar fails — propose a local stub.
- **Apply only with approval, per batch.** Never modify the repo without the user okaying that batch.
  Surface package-lockdown's "commands to run" rather than silently installing.
- **Don't force inapplicable pillars.** A library legitimately has no visual path / no datastore;
  declare those out in Stage 0 instead of reporting false gaps.

Grow this section after each audit: any false pass or false gap you hit is a new gotcha.
