---
name: security:harden-plan
description: Produces a prioritized, tiered hardening plan for a target system, enumerate its current controls, grade each through the spine, gap them against Tier 1/2/3, and emit a remediation ladder. Complements assess-attack-surface (which scores exposure + cadence); this one says what to FIX and in what order. Triggers on, hardening plan, how do we harden X, remediation plan, what should we fix first, close the gaps on X, tier the fixes for, harden roadmap, /security:harden-plan.
model: opus # opus supervises; REAL weakness-finding and judgment are delegated to the Fable workers via fable:hunt (see spine "Execution"). (scaffold: added 2026-08; retest each model release.)
---

# /security:harden-plan: the remediation ladder

Turns a target system into an ordered, tiered list of concrete fixes. Where `security:harden`
grades one control, this grades a whole system's posture and outputs the plan to close it.

## First, always

Read the spine: `/Users/derek/dotfiles/claude/commands/security/harden/references/spine.md`.
Then, if the target is an eBacon system, read its `~/eBacon/attacksurface.md` entry (current
controls, open findings, criticality) as the starting posture. Portable-but-aware: for a
non-eBacon target, enumerate posture from whatever the user provides (repo, description).

## Boundary vs assess-attack-surface

Do not redo the assessment. `assess-attack-surface` answers *how exposed is this and how often
should we test it*. This skill answers *given that exposure, what do we fix and in what
order*. If no recent assessment exists and the posture is unclear, say so and suggest running
`/security:assess-attack-surface <system>` first rather than guessing exposure here.

## Where the security judgment runs

For a REAL system the judgment is not authored here. Per the spine's Execution policy, route
it through the `fable:hunt` skill (the Fable workers behind the recovery harness):
- finding real weaknesses in the code/config -> `fable:hunt` with `vuln <scope>` (and `bug`
  if correctness gaps are in scope)
- grading each control and prioritizing the ladder (severity / tier / real-vs-noise calls) ->
  `fable:hunt` with `assess <collated findings + "tier these and order the fixes">`

You orchestrate (scope, invoke, relay); do not spawn the Fable agents directly or overrule
their verdict. If `fable:hunt` reports a coverage gap from repeated self-stops, surface it and
fall back to `security-auditor` (Opus) for the un-covered slice.

## Method

1. **Enumerate current controls** for the target (from the inventory entry + repo metadata),
   and for a real system surface its weaknesses via `fable:hunt` (`vuln`/`bug`) rather than
   reading the code inline; keep only the structured control + finding list in session.
   Respect the AV concurrency cap (<=4).
2. **Grade each control** through the spine (survives-what / root-of-trust / boundary-vs-
   scaffold). Note which are Tier 1 wearing a Tier 2 label.
3. **Gap against the ladder:** for each tier, what is missing? A system strong at Tier 1 but
   empty at Tier 3 has no breach answer, call that out.
4. **Order the fixes** by (risk closed) / (cost + blast-radius of the change). Cheap high-
   leverage boundaries first; expensive or disruptive ones flagged with their cost. Mark each
   fix with its tier and whether it is a boundary or hardening-in-depth.

## Output

A plan file (Markdown), path printed and nothing else (house rule: never auto-open):
- eBacon target -> `~/eBacon/hardening/<system>-hardening.md`
- otherwise -> the current working directory, `<system>-hardening.md`

Structure: one-line posture summary; the tiered gap table (Tier | gap | current | proposed |
boundary? | cost); then the ordered remediation ladder with a why per item. Sensitive detail
(hosts, secret locations) follows the same rule as the inventory, names/paths only, and if
the target is an eBacon system the plan is security-sensitive, keep it under `~/eBacon/`
(outside every git repo), never in the public dotfiles repo or an artifact.

## Gotchas

- **A plan that is all Tier 1 is not a hardening plan.** If you only produced account/console
  fixes, you have not addressed platform compromise or breach; say so explicitly rather than
  letting the list imply coverage.
- **Order by leverage, not by tier number.** A cheap Tier 3 egress rule can outrank an
  expensive Tier 2 rebuild. The ladder is risk-per-cost, not a march through the tiers.
- **Do not invent posture.** If you cannot see a control in the inventory or repo, mark it
  `unknown/verify`, never assume it exists or is absent. Same discipline as the inventory.
- **Read-only against infrastructure.** Propose fixes; do not deploy, restart, or change live
  systems. Implementation is a separate, explicitly-authorized step.
