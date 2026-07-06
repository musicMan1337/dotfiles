---
name: security:assess-attack-surface
description: Deep, adversarially-verified security assessment of one or more eBacon attack surfaces, then a testing-cadence recommendation per system based on criticality and cost. Reads the inventory at ~/eBacon/attacksurface.md, confirms targets, runs the assess-attack-surface workflow, and writes results back to the Assessment Log. Triggers on, assess attack surface, assess our surface, security assessment, pentest planning, how often should we test, testing cadence, assess a service, deep security review, /security:assess-attack-surface.
model: opus
---

# /security:assess-attack-surface

Scout + gate + launcher + reporter for the attack-surface assessment workflow. This file runs in-session (target selection, the human gate, and the write-back to the sensitive inventory file). The verbose per-system, per-dimension security review lives in the **dynamic workflow** (`assess-attack-surface.workflow.mjs`), so the fan-out output never floods this context.

## Constants

- **Inventory file (`THE_FILE`):** `/Users/derek/eBacon/attacksurface.md` — sensitive, lives **outside every git repo** (dotfiles is public). Never commit it, never paste it externally.
- **Workflow script:** `/Users/derek/dotfiles/claude/commands/security/assess-attack-surface.workflow.mjs`
- **Scope:** `TAGEmployerServices` org repos only.

## Hard rules

- **Read-only against infrastructure.** This is authorized assessment of the operator's own systems. Agents read repo metadata/config/source; they do NOT deploy, restart, scan live hosts, or hit live endpoints. Live testing (DAST, auth fuzzing) is out of scope for this command; if the user wants it, plan it separately and get explicit per-target authorization.
- **No secret values** ever land in `THE_FILE`, the report, or any agent output. Names/paths only.
- **The human gate is here, not in the workflow.** Workflows run autonomously and cannot pause for `AskUserQuestion`. Pick targets and confirm here, then launch.

## Phase 1: Pick targets (inline)

1. Read `THE_FILE`. Parse the At-a-glance table and the per-system entries.
2. Determine the target set from the argument:
   - `<system name>` (or several) → just those.
   - `all` → every system in the inventory.
   - `overdue` (default when no arg) → any system whose (Last assessed + Cadence) is in the past, or "never". Compute against today's date.
   - `critical` / `high` → all systems at that criticality.
3. For each target, gather `{ name, repo, path, type, criticality, exposure, entry }` from its inventory entry (`entry` = the full markdown block, passed to the workflow as the recon prior). Resolve `path` under `~/eBacon/` and confirm origin is in the TAG org.
4. Print the target set as a numbered list with criticality + why-selected, plus a rough cost signal (Critical/High systems run the full 6-dimension deep pass with multi-vote verification; Medium/Low run a lighter pass). Example:

   ```
   Assess 3 systems:
   1. Viper        🔴 Critical  — overdue (never assessed)   [deep: 6 dims, 2-vote verify]
   2. Texting      🟠 High      — overdue                     [deep: 6 dims]
   3. Snout        🟡 Medium    — annual, due                 [light: 4 dims]

   Run the assessment workflow over these 3?
   1. Yes
   2. Narrow the list
   3. Cancel
   ```
   **Wait for confirmation.** If narrowed, re-print and re-ask.

## Phase 2: Launch the workflow

Once confirmed, stamp today's date (the workflow has no `Date` access) and call **Workflow** with the saved script. Do NOT fan out assessment agents yourself; the workflow owns the fan-out, depth policy, throttling, adversarial verification, schema validation, and cadence math.

```
Workflow({
  scriptPath: "/Users/derek/dotfiles/claude/commands/security/assess-attack-surface.workflow.mjs",
  args: {
    today: "<YYYY-MM-DD>",
    filePath: "/Users/derek/eBacon/attacksurface.md",
    targets: [
      { name: "Viper", repo: "TAGEmployerServices/Viper", path: "/Users/derek/eBacon/Viper",
        type: "web+api", criticality: "Critical", exposure: ["PUBLIC","TOKEN"],
        entry: "<the full ### Viper markdown block from THE_FILE>" }
      // ... one per confirmed target
    ]
  }
})
```

The workflow runs in the background; you are notified on completion. Use `/workflows` to watch live progress. It returns `{ assessments: [...] }`, each matching `ASSESSMENT_SCHEMA`: `system, recommended_criticality, recommended_cadence, cadence_rationale, cost_note, next_due, log_row, summary, confirmed[]`.

**What the workflow does per system** (depth scales with criticality, so cost tracks risk):
- **Recon** (Sonnet) — confirm the live surface + report drift vs the inventory entry.
- **Assess** (Sonnet, Opus for Critical / injection+authz dims) — 6 security dimensions for Critical/High, 4 for Medium, 3 for Low.
- **Verify** (Opus for C/H findings, else Sonnet) — adversarial skeptics try to REFUTE each finding; majority kills false positives.
- **Score** (Opus) — risk score + cadence, starting from a deterministic prior that already weighs criticality, exposure, worst finding, and this run's agent cost.

## Phase 3: Report + write back

1. **Report** a single terminal table, most-critical first:

   ```
   System     | Crit (was→now) | Confirmed C/H/M/L | Cadence (was→now)  | Next due | Top finding
   -----------|----------------|-------------------|--------------------|----------|-------------
   <system-a> | 🔴 (=)         | 0/2/3/1           | Quarterly (=)      | 2026-10  | <one-line top finding>
   <system-b> | 🟠→🔴          | 1/0/1/0           | Semi→Quarterly     | 2026-10  | <one-line top finding>
   ```
   (Illustrative shape only. Real system names + findings stay in `THE_FILE`, never in this public-repo command.)
   Then one line per system with `summary` and `cadence_rationale`. Do not dump every finding; lead with confirmed Critical/High.

2. **Write back to `THE_FILE`** (this is the only surface this command edits, plus each system's row):
   - Append each `log_row` to the **Assessment log** table.
   - Update each assessed system's **At-a-glance** row and per-system entry: `Last assessed` = today, `Cadence` = `recommended_cadence`, and criticality if `recommended_criticality` changed (note the change).
   - If verification confirmed a finding not already in that system's **Open findings**, add it (names/paths only).
   - Never rewrite unrelated entries. Keep the At-a-glance and perimeter tables consistent (hand off to `/security:attack-surface sync-tables` if they drift).
   - Confirm the edit stayed in `~/eBacon/attacksurface.md` and did not touch any repo.

3. **Close** with the next-due summary: which systems are now scheduled when, and any that failed recon and need an individual re-run (`Workflow({scriptPath, resumeFromRunId})` resumes cached systems).

## Gotchas

- **Security-review agents are pinned to Sonnet/Opus, never the session model.** The session model (Fable) false-refuses cyber review (that is why the pinned auditor agents avoid it). The workflow sets an explicit non-Fable `model` on every agent; do not "simplify" that away.
- **Depth is the cost lever.** A Critical system costs ~15-25 agents (6 dims + 2-vote verify + score); a Low system costs ~5. That asymmetry is intentional. Assess `overdue` regularly rather than `all` every time.
- **Cadence is risk ÷ cost, not just criticality.** The workflow down-ranks cadence for low-risk systems that are expensive to assess, so a public-but-simple service does not get pointless monthly reviews. Trust the rationale; override with judgment if you disagree, and edit the entry.
- **Drift is a signal.** If recon reports drift vs the inventory, the entry is stale — run `/security:attack-surface update <system>` to refresh it (this command reports drift but does not re-discover the full entry).
- **Resume after a hang.** One system's deep pass hanging does not lose the others; relaunch with `Workflow({scriptPath, resumeFromRunId})`.
