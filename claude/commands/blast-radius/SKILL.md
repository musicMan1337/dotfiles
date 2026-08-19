---
name: blast-radius
description: Find what a change breaks somewhere else, beyond the diff, and prove the one fact it is safe because of by running code instead of writing it up. Triggers on, blast radius, blast radius of, what could this break, what else touches this, is this change safe to ship, what depends on this, review this diff I do not trust, side effects of this change, /blast-radius.
---

# blast-radius

Adapted from the `blast-radius` skill in [pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT, Lauren Tan).

Listing the callers is not the job. Grep does that in a second. The job is the breakage grep will not show.

## Do not trust the writeup

A blast-radius writeup that sounds right is worthless: it reads as convincing whether or not it is true. So the deliverable is not the writeup. Find the one or two facts the change's safety depends on and prove them by running code.

### How sure are you

Take each safety fact as far down this list as is cheap, then say where it stopped.

1. **Asserted.** Worthless alone.
2. **Cited.** A real `file:line`, or the dependency's own source.
3. **Reasoned.** Walked the failure step by step and it does not reach.
4. **Executed.** A script or test that calls the real code and fails loud if the fact is wrong.
5. **Reproduced.** Observed in the running app.

Anything that stops short of rung 4 is marked unproven, out loud. Do not round up.

Rung 4 is usually one small script that imports the same dependency the app ships and calls the exact function in question.

**Mapping to the correctness verdict in CLAUDE.md:** rung 4 or 5 on every safety fact supports *Proven*. A fact stuck at rung 2 or 3 makes it *Proven under stated assumptions*, and the assumption to name is that fact. No reachable rung above 1 means *Not provable as written*, which is a legitimate result and gets reported as one.

## Steps

1. **Read the change.** The diff, the symbols added, changed, and deleted, and what now behaves differently, including the part the diff does not spell out.
2. **Find the one fact it is safe because of.** Most alarming-looking changes are safe because of a single fact ("this only drops already-dead cache entries"). Find it. If it holds, most of the scary cases die at once. Spend the time here, not on a list of maybes.
3. **Look where grep stops.** Read the source of the dependency actually installed, and check its pinned version and any patch. Work out when things run: microtasks, teardown, transaction boundaries, trigger cascades. Follow what a symbol search misses: the JSON an endpoint returns, a DB column, a wire format, a feature flag, another repo reading the same bytes, code three hops downstream.
4. **Be honest per risk.** Real likelihood, real cost. Keep the confirmed ones; list what was checked and cleared separately. Cite a real `file:line`. A search that finds nothing is still an answer. Never invent a caller or an API.
5. **Prove the one fact.** Write the script, run it, paste what happened. Cheap to prove means prove it now. Expensive means mark it unproven.
6. **Wide changes get more than one reader.** Spawn independent reviewers on the same question and merge, within the concurrency caps in CLAUDE.md.

## Where grep stops in this stack

- **SQL.** Dynamic SQL built as strings, sproc-to-sproc calls, triggers, and views that read the changed column. The SQL MCP is ground truth; never infer schema or sproc behavior.
- **Viper monorepo.** A changed package export crosses component boundaries, and CI hard-fails on an undeclared internal workspace dep.
- **Wire shapes.** A renamed field in a JSON response has consumers that no TypeScript reference finds.
- **Jobs and schedules.** Cron, queue consumers, and CI workflows call code that no application path calls.

## Output

- **What it does.** Including the part that is not obvious from the diff.
- **The one safety fact.** Stated, with the rung it reached and the proof pasted, or the word unproven.
- **Risks.** Only real ones. Each names how it breaks, a `file:line`, likelihood, cost, and how to check.
- **Cleared.** What was checked and why it is fine.
- **Before merge.** The cheapest test or repro that catches the real bug, including the script written above.

## Gotchas

- Prose expands to fill the space. A long risk list usually means step 2 was skipped.
- The output is public-adjacent (PR bodies, case notes), so strip anything sensitive before it leaves the session.
