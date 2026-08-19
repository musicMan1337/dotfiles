---
name: grill
description: Relentless interview that maps a plan, design, or decision as a tree and works it in rounds until nothing is left silently assumed. Triggers on, grill me, grill this, grill me on, stress test this plan, poke holes in this, interview me about, sharpen this idea, what am I missing here, pressure test the design, /grill.
---

# grill

Adapted from the `grilling` skill in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, Matt Pocock).

Interview the user relentlessly until a shared understanding is reached. Do not act on the plan until they confirm it.

## The tree

Map the subject as a **design tree**: every decision branches into the decisions that hang off it.

The **frontier** is every decision whose prerequisites are already settled, so it can be asked now without guessing at an answer not yet given. A question whose answer depends on another question still open in this round belongs to a later round.

Work in **rounds**. Ask the whole frontier in one round, then wait. Each answer reshapes the tree: settled decisions push the frontier outward and unblock what depended on them. Recompute and ask the next round.

Done when the frontier is empty, every branch visited, nothing left silently assumed.

## Round format

One numbered block per question, recommended answer attached. The recommendation is what makes a long round cheap to answer.

```
**Q3 - Retry ownership**
Does the worker retry, or does the queue redeliver? Retry-in-worker keeps the
failure local but hides it from the queue's metrics.
a) worker retries, capped at 3
b) queue redelivers, worker is stateless
Rec: (b), the metrics matter more than locality here.
```

Numbered free text, not `AskUserQuestion`. A real frontier round runs 5 to 12 questions, past that tool's 4-question ceiling, and answering `1a 2b 3a` in one line is faster than four sequential dialogs. Rounds of four or fewer questions may use the tool.

## Facts are yours, decisions are theirs

Never ask for something observable. Filesystem, repo history, schema, config, current behavior: go look.

- Delegate the lookup to `reader` (scoped paths and globs only, per the search rules in CLAUDE.md), never to a repo-wide sweep.
- Never assert DB behavior from inference. A schema or sproc question goes to the SQL MCP.
- Do not block on a lookup. A running exploration is an unsettled prerequisite, so only the questions downstream of it wait. Ask the rest of the frontier now.

The decisions are the user's. Put each one to them and wait.

## Gotchas

- The failure mode is asking one question at a time. That turns a 3-round interview into 30 turns.
- The second failure mode is asking a question the repo answers. Every such question spends the user's attention on work already delegable.
- Recommendations are real judgments, not filler. Disagreement is the point: an answer that overrides the recommendation is the highest-signal reply in the round.
- Pair with `docs:create` when the decisions deserve an ADR, and with `spec:developer` when the output is a spec. Grill first, write second.
