---
name: research:orderings
model: sonnet
description: Research a topic with multiple context orderings to minimize gaps. Triggers on: deep research, thorough investigation, multi-angle research
---

# research:orderings

Goal: answer the research question thoroughly using multiple independent perspectives, and report consensus vs single-source findings with honest confidence levels.

**Dated premise (re-test each model release):** the signature technique here, running the SAME materials through parallel subagents in DIFFERENT orders, compensates for "Lost in the Middle" positional bias observed in 2025-era long-context models. Before reaching for it, judge whether it still pays: if current models attend uniformly across long contexts, a plain perspective fan-out (different lenses, not different orders) or even a single long-context pass gives the same coverage cheaper. The rest of this skill applies either way; the ordering shuffle is the deletable part.

## Input

Research task: $ARGUMENTS (if empty, ask what to research).

## Approach (adapt to the task; none of this is a fixed pipeline)

- Delegate bulk reading and heavy synthesis to subagents so raw materials never land in the main session; you hold the plan and the compact reports. Tier picks per `dotfiles/claude/TIERS.md` (`reader` scouts, sonnet-tier workers, opus-tier synthesis only when genuinely cross-referencing many reports); set a model or pinned agent on every spawn, the subagent-gate denies unpinned catch-alls.
- Typical shape: enumerate the materials, fan out independent workers (varied orderings, groupings, or lenses: thematic, chronological, source-type, adversarial), synthesize in a fresh context, iterate on gaps. 2–3 cycles max; diminishing returns are fast.
- Independence between workers matters more than any particular ordering scheme.
- Respect the subagent cap (4/session, 6 machine-wide): batch waves.

## Report

Direct answer; key findings ranked by confidence (consensus vs single-worker, say which); contradictions; remaining uncertainties; most informative sources.

Then offer: 1. `/obsidian:investigate` to log the research; 2. `/research:execute` to act on findings.
