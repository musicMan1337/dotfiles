---
name: research:orderings
model: sonnet
description: Research a topic with multiple context orderings to minimize gaps. Triggers on: deep research, thorough investigation, multi-angle research
---

# research-orderings

You have been given a research task. You will use the **context ordering technique** to minimize "Lost in the Middle" effects and uncover insights that a single-pass approach would miss.

The core idea: when subagents consume the same research materials in different orders and groupings, each ordering surfaces different insights due to positional bias in context windows. By running multiple orderings in parallel, delegating synthesis to a fresh subagent, and iterating — you catch gaps and reduce false positives.

## Your Role: Pure Orchestrator

**You are a coordinator, not a worker.** Your main session context is precious — it must stay clean so you can run multiple cycles of scout/worker/synthesize without compaction.

What you do:
- Design orderings and prompts
- Dispatch subagents
- Read subagent reports
- Decide whether to iterate
- Present the final result

What you **do not** do:
- Read research materials yourself (subagents do this)
- Perform synthesis yourself (a synthesizer subagent does this)
- Implement anything directly

This keeps bad context, failed attempts, and verbose material out of your main session. Each subagent gets a fresh context window, which means fresh thinking and no pollution from prior cycles. Your 1M token context window is reserved for holding the high-level plan plus the compact reports from many subagents across multiple cycles.

## Input

**Research task:** $ARGUMENTS

If no arguments were provided, ask the user what they'd like researched, then proceed.

## Model Tiers

Set `model` explicitly on **every** Agent call. Never omit it — default inheritance silently runs Haiku-tier work on Opus, wasting tokens and money for zero benefit:

| Role | Model | Why |
|------|-------|-----|
| **Orchestrator** (you) | Sonnet | Coordination and ordering design — no heavy reasoning needed |
| **Scouts** (Phase 1) | **Haiku** | Pure file/web lookup, no analysis required |
| **Workers** (Phase 3) | **Sonnet** | Research and reasoning — Sonnet handles this well at ~1/5 the cost |
| **Synthesizer** (Phase 4) | **Opus** | Cross-referencing, contradiction detection, and nuanced judgment — this is where Opus matters |
| **Follow-up workers** (Phase 5) | **Sonnet** | Same as initial workers |

This is not a suggestion — set the `model` parameter on every single Agent call. Omitting it defaults to Opus, which means you're paying 30x more for a file lookup that Haiku handles identically.

## Phase 1 — Scope and Gather (Scout)

Spawn **Haiku explorer subagents** to understand the research landscape. Scouts only read and locate — they don't analyze.

1. **Understand the research question.** What exactly needs to be answered? What would a complete answer look like?

2. **Identify research materials.** Dispatch Haiku scout subagents to locate relevant materials:
   - Files in the codebase (logs, source code, configs, docs)
   - Web sources to fetch
   - A combination of both

3. **Enumerate the material.** From scout reports, build an explicit list of all items (files, URLs, sections, documents) that the research subagents will consume. This list is the "deck" you'll shuffle.

## Phase 2 — Design Orderings

Before spawning any research subagents, **stop and think about orderings**. This is the critical step that you (the orchestrator) perform directly — it's lightweight planning, not heavy research.

Consider the nature of the problem and choose 3-5 ordering strategies from approaches like:

| Strategy | When to use | Example |
|---|---|---|
| **Original order** | Baseline — preserves natural structure | Files as found on disk |
| **Reversed** | Surfaces items normally buried at the end | Reverse of original |
| **Random shuffle** | Breaks all positional bias | Randomized order |
| **Grouped by theme/topic** | Domain-heavy research | Group related docs together |
| **Grouped by source type** | Mixed-source research | All papers, then all code, then all logs |
| **Grouped by methodology** | Technical/scientific research | Group by approach used |
| **Grouped by conclusion/outcome** | Comparative research | Group by what they found |
| **Grouped by severity/importance** | Debugging/triage | Critical items first vs last |
| **Grouped by recency** | Time-sensitive research | Newest-first vs oldest-first |
| **Grouped by author/origin** | Multi-author analysis | Cluster by who wrote it |

**Choose orderings that are meaningfully different from each other.** The goal is maximum coverage — each ordering should place different items in the attention-favored positions (beginning and end of context).

Write out your chosen orderings and briefly justify why each one is useful for this specific problem.

## Phase 3 — Parallel Research (Workers)

Spawn one **Sonnet** subagent per ordering. Each subagent gets a **fresh context window** — this is critical. Fresh context means fresh thinking, no pollution from prior work, and focused attention on its specific ordering.

Each worker subagent receives:

1. **The research question** — identical across all agents
2. **The materials in their specific order** — this is what varies
3. **Instructions to be thorough** — extract every relevant insight, finding, connection, and contradiction

The prompt to each subagent should include:
- The full research question
- The ordered list of materials to consume (with the actual content or paths)
- A request to list all findings with supporting evidence
- A request to note any uncertainties, contradictions, or gaps
- A request to flag which items felt most/least salient (this helps detect positional bias)
- An instruction to return a **structured report** (not a wall of text) — this keeps main session context compact

**Run all subagents in parallel.**

## Phase 4 — Synthesize (Synthesizer Subagent)

**Do NOT synthesize in the main session.** Delegate synthesis to a dedicated **Opus** subagent with a fresh context window. This is the one phase that genuinely benefits from Opus — it must cross-reference multiple reports, detect contradictions, evaluate confidence levels, and identify positional bias. Use `model: "opus"` explicitly.

The synthesizer subagent receives:
- The original research question
- All worker reports (the compact structured reports, not raw materials)
- Instructions to perform the following analysis:

1. **Collect all findings** into a unified view
2. **Identify consensus** — findings reported by multiple orderings are high-confidence
3. **Identify unique findings** — insights found by only one ordering. These are "Lost in the Middle" recoveries. Evaluate whether they're genuine insights or noise.
4. **Identify contradictions** — where orderings disagree, flag for deeper investigation
5. **Identify gaps** — what questions remain unanswered?
6. **Cross-reference salience** — if a worker flagged an item as "not very informative" but another worker (with that item in a different position) found it critical, that's a positional bias detection
7. **Produce a synthesis report** with: consensus findings, unique findings (with confidence assessment), contradictions, gaps, and a recommended next step (iterate or done)

Why delegate synthesis? Because the synthesizer gets a fresh perspective without any of the accumulated context from your orchestration. It sees only the distilled reports and can reason about them cleanly.

## Phase 5 — Iterate (if needed)

Read the synthesizer's report. If it identifies significant gaps or contradictions:

1. Design targeted follow-up **Sonnet** worker subagents that focus specifically on the gaps
2. Consider new orderings that place gap-related materials in attention-favored positions
3. Spawn follow-up workers in parallel
4. Delegate re-synthesis to a **new Opus** synthesizer subagent (fresh context again)

Each cycle uses only the compact reports from your subagents, so your main orchestrator context grows slowly — you can comfortably run 2-3 cycles before context becomes a concern.

Repeat until the synthesizer reports that:
- The research question is thoroughly answered
- No major contradictions remain unexplained
- The findings are well-supported by evidence

## Phase 6 — Report

Present the final synthesis to the user. You can lightly edit the synthesizer's report, but avoid re-analyzing the raw findings yourself. Present:

1. **Answer** — direct answer to the research question
2. **Key findings** — the most important insights, ranked by confidence (consensus vs single-ordering)
3. **Methodology note** — how many orderings were used across how many cycles, and what the ordering diversity revealed (e.g., "3 of 4 orderings agreed on X; ordering-by-theme uniquely surfaced Y")
4. **Remaining uncertainties** — what couldn't be fully resolved
5. **Sources** — which materials were most informative

## Rules

- **You are a coordinator.** Do not read research materials or perform synthesis in the main session. Delegate everything to subagents.
- **Always design orderings before spawning agents.** The ordering design is the intellectual core of this technique — it's the one thing the orchestrator does think deeply about.
- **Use tiered models.** Haiku for scouts, Sonnet for workers, Opus for synthesis only. Always set `model` explicitly on every Agent call — never rely on default inheritance.
- **Maximize parallelism.** All orderings of the same phase run simultaneously.
- **Keep main context clean.** Subagents return compact structured reports. Bad context from failed attempts stays trapped in the subagent's context and gets discarded — only the summary returns.
- **Fresh context = fresh thinking.** Each subagent starts with a clean slate. This avoids the creativity/novelty degradation that occurs when a single context accumulates too much history.
- **Be honest about confidence.** Single-ordering findings are lower confidence than consensus findings. Say so.
- **Don't over-iterate.** 2-3 cycles is usually sufficient. Diminishing returns set in quickly.
- **Adapt ordering strategies to the domain.** Debugging logs need different orderings than research papers.

## Next Steps

After presenting the final report, offer the user two follow-up options:

1. **Document the findings:** Ask if they want to run `/obsidian-investigate` to log this research as an investigation note in Obsidian — capturing the key findings, dead ends, and open questions so they don't have to re-do this research later.

2. **Act on the findings:** If the research produced actionable findings, mention they can run `/research-execute` to spawn sub-agents that implement changes, apply fixes, or follow through on recommendations.
