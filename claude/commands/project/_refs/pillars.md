# The Three Pillars (non-negotiable)

These outrank whatever stack the user "expected." Stage 1 research must treat them as hard
constraints on tech-stack selection, not nice-to-haves bolted on afterward. A stack that can't
satisfy an applicable pillar is disqualified, even if it's the popular default.

A pillar is *applicable* based on project shape (see "Conditional application" at the bottom).
Don't force a pillar where it makes no sense (a pure library has no visual path; a stateless CLI
has no datastore). But where it applies, it is mandatory.

---

## Pillar 1 — Agent development is a first-class citizen

An agent must be able to spin up the app and exercise it **without a human in the loop**, along
two independent paths:

- **Functional path (logical):** boot the app headlessly and drive it programmatically to assert
  behavior. No GUI, no manual clicking. Pure logic in, assertions out.
- **Visual path:** render the app in isolation and capture/inspect its visual state so an agent can
  verify appearance and catch visual regressions, again with zero human interaction.

These are **separate paths**, not one tool doing double duty. The functional path must work even if
the visual path is broken, and vice versa.

Control-surface preference, strongest first:
1. **Direct CLI control** of the app (preferred). The agent invokes the app or a thin CLI harness
   directly. Deterministic, scriptable, no broker process.
2. **MCP integration** (only when no CLI path is practical). A tool server the agent talks to.

Bias warning: **do not default to Playwright** (or any single tool) for the visual path. Evaluate
the current best option for the chosen framework at research time. Candidates shift over time and
include (non-exhaustive): component test runners, browser-mode unit runners, story/isolation
harnesses, screenshot/diff tools, framework-native render-test utilities, and yes Playwright. Pick
on merit for this stack, this year. New tools may have emerged since training cutoff, so research it.

What "done" looks like: there is a documented, agent-runnable command for (a) booting the app for
functional testing and (b) rendering/inspecting it visually in isolation. If the user picked
autonomous mode, scaffold a minimal working example of each.

---

## Pillar 2 — Red-green testing is mandatory

A test that has only ever passed proves nothing. It may be asserting on the wrong thing, asserting
trivially, or not running at all. **Every test must have a demonstrated red state before its green
state is trusted.**

Operationally:
- The chosen test setup must make it cheap to flip a test red (break the code under test, or invert
  the assertion) and observe the failure, then restore green.
- The convention to capture this must be set up at project creation: a documented red-green workflow,
  not left to chance.
- In autonomous mode, scaffold at least one **exemplar** that demonstrates the cycle: a test that is
  shown failing against broken/absent code, then passing once the code is correct. This is the proof
  the harness actually tests what it claims.

When wiring tests later (or auditing existing ones), a green-only suite is a finding, not a pass.
Treat "I wrote the test and it passed first try" as suspicious until the red path is shown.

---

## Pillar 3 — The database (and any external dependency) runs locally first

First iteration must run on a **locally runnable, stubbable** datastore and external surface. No hard
dependency on a hosted/managed service to boot, test, or develop.

- Datastore: containerized, embedded, or in-memory equivalent that an agent can start locally.
- Other external dependencies (queues, object storage, third-party APIs): stub or emulate locally.
- Even if the user names a hosted provider, **wire the local stub first.** Moving to pure hosted is
  a deliberate **post-creation** decision, explicitly out of scope for `project:new`.

What "done" looks like: `clone → one documented command → app + datastore up locally`, with no cloud
credentials required for the first iteration.

---

## Conditional application (type-agnostic)

This skill targets any project type. Apply pillars by shape:

| Project shape          | Pillar 1 functional | Pillar 1 visual | Pillar 2 red-green | Pillar 3 local DB |
|------------------------|---------------------|-----------------|--------------------|-------------------|
| Full-stack / UI app    | yes                 | yes             | yes                | yes (if stateful) |
| Backend / API / service| yes                 | only if it serves UI | yes           | yes (if stateful) |
| CLI tool               | yes                 | no              | yes                | only if stateful  |
| Library / SDK          | yes                 | no              | yes                | no                |

Decide applicability in Stage 0 from the intake context, and state which pillars are in/out and why
before researching the stack. Skipping a pillar must be a justified decision, never an oversight.
