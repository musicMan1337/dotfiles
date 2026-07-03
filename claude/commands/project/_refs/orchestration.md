# Orchestration flow (shared by project:new and project:audit)

This is the staged pipeline both entry points run. Differences between **new** (greenfield, write
fresh) and **audit** (existing repo, diff then apply-with-approval) are called out inline as
`NEW:` / `AUDIT:` notes. Read [pillars.md](./pillars.md) first; the pillars are the constraints this
flow enforces.

**Operating rules (these fight Claude's defaults, follow them):**
- You are the orchestrator. **Delegate all search/lookup to Haiku subagents.** Never grep/read the
  ecosystem yourself. Reserve your context for decisions and the reconciliation loop.
- The orchestrated skills (`research:orderings`, `setup:package-lockdown`, `setup:linting`) already
  fan out their own subagents and verify against live registries. Invoke them; do not reimplement
  their work. Pass them the scope hint they expect (`new` vs `audit`).
- **Never invent or guess package versions.** package-lockdown verifies against live registries and
  date-stamps pins. Respect its "user runs these commands" output; it does not auto-install.

---

## Stage 0 — Intake

**NEW:**
- Ask the user for a **project name** (chat about ideas if they want help naming). Keep it light.
- Gather just enough about what the project is: purpose, rough shape, any hard tech constraints.
- Determine project shape and **declare which pillars apply** (see the table in pillars.md). State
  in/out and why before researching.
- **Offer `/autonomous-mode`:** "Want me to build a full working prototype autonomously, or run this
  interactively with you at each stage?" If yes, the rest of the pipeline runs without further
  questions and ends with a committed, runnable prototype. If no, checkpoint at each stage.

**AUDIT:**
- Detect the existing project: languages, frameworks, package manager(s), lockfile state, test setup,
  lint/format config, CI, datastore wiring. (Delegate this discovery to a Haiku subagent.)
- Determine project shape and which pillars apply, same as new.
- No project-name question. No autonomous prototype build. The deliverable is a **scored gap report**
  against the pillars + hardening expectations, then fixes applied **per approved batch**.

---

## Stage 1 — Tech-stack research (`/research:orderings`)

Build the research question from intake context, but **inject the applicable pillars as hard
constraints**, not as a trailing wish. The primary research goal is: *which stack best satisfies the
pillars for this project*, with the user's stated preferences as secondary inputs.

The question must force the research to answer, for each candidate stack:
- Functional + visual agent-dev paths (Pillar 1): what tools, CLI-first, is the visual path real and
  current (no Playwright bias)?
- Red-green ergonomics (Pillar 2): how cheaply can a test be flipped red and back?
- Local-first datastore/deps (Pillar 3): what's the local stub story?
- Current best versions and known compatibility traps between the above.

Output: a recommended stack with the specific packages and runtime to lock.

**AUDIT:** frame as "evaluate the *existing* stack against the pillars and surface gaps / better
options," not "pick from scratch." Existing choices stay unless they fail a pillar.

---

## Stage 2 — Lock everything EXCEPT linting (`/setup:package-lockdown`, scope: new|audit)

Run package-lockdown on the chosen stack: runtime, main deps, **test tooling, agent-dev tooling
(functional + visual), and local-datastore tooling**. Lock and harden all of it.

**Do NOT lock linting/formatting tooling here.** This is deliberate. Locking everything at once makes
it impossible to isolate which peer/engine conflict the lint toolchain introduces in Stage 3. The
two-phase split exists precisely so Stage 3 conflicts are attributable.

Capture the locked versions; they are the baseline the Stage 3 loop reconciles against.

---

## Stage 3 — Linting decision + second lockdown, with a reconciliation loop

This is the chicken-and-egg resolution. You can't pick the lint toolchain until the stack is locked,
but the lint tooling is itself packages that must be hardened.

- **3.1** `/setup:linting` — decide the lint/format/typecheck toolchain + hook framework based on the
  **Stage 2 locked stack** (it adapts to the languages/frameworks present).
- **3.2** `/setup:package-lockdown` (scope: `add-package` style) on **only the lint tooling** Stage 3.1
  introduced. Harden + pin those.

**Reconciliation loop:**
1. Resolve the lockfile with main stack (Stage 2) + lint tooling (3.2) together.
2. If it resolves cleanly (no peer-dep, engine-range, or shared-dep-version conflicts) → done, exit
   loop.
3. If a conflict comes from the lint tooling alone (e.g. a plugin pins an older parser) → adjust the
   lint tooling choice/version and re-run 3.2. Loop.
4. If resolving **requires changing a Stage-2-locked main-stack version** (TS version, runtime,
   framework major):
   - **Interactive / audit:** PAUSE. Surface the conflict and the proposed main-stack change as
     numbered options; let the user choose. If accepted, loop back to Stage 2 to re-lock the affected
     piece, then re-enter Stage 3.
   - **Autonomous:** decide the minimal-blast-radius change, log it, re-lock, and continue.
5. **No-progress guard:** if two consecutive loop iterations don't reduce the conflict set, stop and
   report the unresolved conflicts as numbered options rather than thrashing.

---

## Stage 4 — Verify the pillars are actually wired

Don't trust that selecting tools wired them up. For each **applicable** pillar, confirm a real,
runnable artifact exists (delegate the checks to subagents):

- **Pillar 1 functional:** a documented command boots the app headlessly and an agent can drive it.
- **Pillar 1 visual:** a documented command renders/inspects the app in isolation. CLI-first; MCP only
  if no CLI path.
- **Pillar 2 red-green:** the red-green convention is documented. Autonomous mode: a working exemplar
  test that has been shown red then green.
- **Pillar 3 local-first:** `clone → one command → app + datastore up locally`, no cloud creds.

Any missing applicable artifact is a gap: fix it (new/autonomous) or report it (audit/interactive).

---

## Stage 5 — Report / handoff

- **NEW interactive:** summary of locked stack, hardening, lint setup, pillar status, and the numbered
  commands the user runs next (package-lockdown emits these; surface them, don't run installs silently).
- **NEW autonomous:** runnable prototype committed via `/git:commit`; report what was built and the
  one command to run it.
- **AUDIT:** scored gap report (per pillar + supply-chain + lint), findings as numbered items, and the
  batches you applied with approval vs deferred.

---

## When to hand the heavy lifting to a Workflow

This flow stays a **skill** because Stage 0 and the Stage 3 pause are interactive, and because it
invokes other *skills* (which a Workflow can't call). But the deterministic fan-out portions are a
good fit for a bundled dynamic Workflow, and it's worth escalating when:

- **Autonomous mode is on** (the user opted in, satisfying the Workflow opt-in requirement) AND
- the work is fan-out heavy: parallel pillar-verification (Stage 4), parallel ecosystem hardening
  checks, or a long reconciliation loop you want to run deterministically without burning orchestrator
  context.

In that case, scout inline (Stages 0–1), then call `Workflow` for Stages 2–4 with the locked stack as
`args`. Keep the interactive stages and any main-stack-downgrade decision in the skill. See the
companion `project.workflow.mjs` only if/when autonomous fan-out is built out; until then the skill
runs the stages directly by invoking the sub-skills.
