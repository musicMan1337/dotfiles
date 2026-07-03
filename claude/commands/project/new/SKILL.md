---
name: project:new
model: opus
description: >
  Bootstrap a brand-new project with an agent-dev-first tech stack, then harden it: pick the stack
  (research), lock + harden all packages EXCEPT linting, set up linting, then a second lockdown pass
  on the lint tooling, reconciling conflicts in a loop. Enforces three non-negotiable pillars:
  agent-runnable functional + visual testing, mandatory red-green tests, and a locally runnable
  database. Triggers on: new project, start a project, bootstrap a repo, scaffold a project, set up
  a new app, greenfield setup, kick off a project, project:new.
---

# /project:new — bootstrap a project, agent-dev-first

Orchestrate a greenfield project so an agent can develop it end-to-end. This is **not** a plain chain
of sub-skills: every stack decision is bent toward three pillars, and the package/linting setup runs
a two-phase reconciliation loop to dodge a chicken-and-egg problem.

**Read both shared refs before acting:**
- [`../_refs/pillars.md`](../_refs/pillars.md) — the three non-negotiable pillars (the core of why
  this exists). Skim once, hold them as hard constraints throughout.
- [`../_refs/orchestration.md`](../_refs/orchestration.md) — the staged flow, the lockdown loop, and
  the per-stage `NEW:` / `AUDIT:` notes. You run the **NEW** path.

You are the orchestrator (opus). The heavy lifting is done by the skills you invoke
(`/research:orderings`, `/setup:package-lockdown`, `/setup:linting`), each of which already fans out
its own Haiku subagents and verifies against live registries. **Don't reimplement their work and
don't search the ecosystem yourself** — delegate any direct lookups you need to Haiku subagents.

## What you do

1. **Stage 0 — Intake.** Ask for a **project name** (offer to brainstorm). Learn what the project is.
   Decide its shape and **declare which pillars apply** (table in pillars.md). Then offer
   `/autonomous-mode`:
   > 1. Build a full working prototype autonomously (no more questions)
   > 2. Run interactively, checkpoint at each stage
2. **Stages 1–5** per orchestration.md: research the stack against the pillars → lock everything
   except linting → linting + second lockdown with the reconciliation loop → verify pillars are
   actually wired → report (or, autonomous, a committed runnable prototype).

## Mode behavior

- **Interactive (default):** checkpoint after each stage with numbered options. **Pause** the Stage 3
  loop before changing any already-locked main-stack version and let the user choose.
- **Autonomous (`/autonomous-mode`):** no further questions; decide minimal-blast-radius changes, log
  them, scaffold the pillar exemplars (functional boot, visual render, a shown red-then-green test,
  local DB up), and commit via `/git:commit`. Escalate Stages 2–4 to a bundled `Workflow` only when
  the fan-out justifies it (see the bottom of orchestration.md).

## Gotchas

- **Pillars are constraints on stack choice, not a postscript.** `/research:orderings` will happily
  return "the popular stack" if you ask loosely. Inject the applicable pillars as hard requirements
  in the research question, and disqualify stacks that can't satisfy them.
- **No Playwright bias.** The visual-testing path must be chosen on merit for the chosen framework and
  current tooling. New/better tools may exist past training cutoff — that's what Stage 1 research is
  for. Same for the functional path: prefer **direct CLI control**, MCP only when no CLI path exists.
- **Don't lock linting in Stage 2.** Locking everything at once destroys the conflict-isolation the
  two-phase split buys you. Lint tooling is hardened in Stage 3.2, after it's chosen.
- **A green-only test is not a passing pillar.** Red-green is mandatory: in autonomous mode you must
  actually show a test red before green; never accept "it passed first try" as proof it tests anything.
- **Local-first DB even if they name a host.** Wire the local stub on iteration one. Migrating to a
  hosted/managed datastore is an explicit post-creation decision, out of scope here.
- **Don't force pillars where they don't apply.** A library has no visual path; a stateless CLI has no
  datastore. Declaring a pillar out is fine when justified in Stage 0 — silently skipping it is not.
- **Never invent versions or auto-install.** package-lockdown verifies live registries and date-stamps
  pins; it emits commands for the user to run. Surface those; don't silently run installs.
- **No-progress guard on the loop.** If two reconciliation passes don't shrink the conflict set, stop
  and present the unresolved conflicts as numbered options rather than thrashing.

Grow this section after each run: any place the pipeline drifted from the pillars is a new gotcha.
