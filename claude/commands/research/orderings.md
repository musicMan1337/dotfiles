---
name: research:orderings
model: sonnet
description: Research a topic with multiple context orderings to minimize gaps. Triggers on: deep research, thorough investigation, multi-angle research
---

# research:orderings

Goal: answer the research question thoroughly using multiple independent perspectives, and report consensus vs single-source findings with honest confidence levels.

## Input

Research task: $ARGUMENTS (if empty, ask what to research).

## Approach (adapt to the task; none of this is a fixed pipeline)

- Delegate bulk reading and heavy synthesis to subagents so raw materials never land in the main session; you hold the plan and the compact reports. Tier picks per `dotfiles/claude/TIERS.md` (`reader` scouts, sonnet-tier workers, opus-tier synthesis only when genuinely cross-referencing many reports); set a model or pinned agent on every spawn, the subagent-gate denies unpinned catch-alls.
- Typical shape: enumerate the materials, fan out independent workers by lens (thematic, chronological, source-type, adversarial) or by grouping, synthesize in a fresh context, iterate on gaps. 2–3 cycles max; diminishing returns are fast.
- Independence between workers is what buys coverage. Running the same materials past several workers in different orders does not: measured 2026-09, retrieval held at 5/5 across depths 4%–96% of an 85K-token corpus.
- Respect the subagent cap (4/session, 6 machine-wide): batch waves.

## Report

Direct answer; key findings ranked by confidence (consensus vs single-worker, say which); contradictions; remaining uncertainties; most informative sources.

Then offer: 1. `/obsidian:investigate` to log the research; 2. `/research:execute` to act on findings.
