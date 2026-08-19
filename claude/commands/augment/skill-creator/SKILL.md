---
name: augment:skill-creator
description: Personal augmentation layer for `skill-creator`. Runs in tandem with (never instead of) it, adding the levers that decide whether an agent-read document actually changes behavior, context pointers, the two loads, the information hierarchy, completion criteria, leading words, and the no-op test. Auto-paired with `skill-creator` by the augment-skill PreToolUse hook.
---

# augment:skill-creator

Adapted from the `writing-for-agents` skill and its `SKILL-MECHANICS.md` in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, Matt Pocock).

`skill-creator` owns placement, naming, and the create-test-iterate loop. This layer owns the writing: the levers that decide whether the document changes behavior at all.

Applies to any document an agent consumes, not just a SKILL.md. `CLAUDE.md`, a doc reached by a pointer, a subagent prompt, a plan. The packaging differs; the writing does not. `docs:create` and `docs:update` should call this layer for the same reason.

## Context pointers

A **context pointer** is a reference held in context that names out-of-context material and encodes the condition for reaching it. A skill's `description` is one. A line in `CLAUDE.md` naming a doc is the same object.

The pointer's wording, not its target, decides when the material gets reached and how reliably. **A must-have target behind a weakly worded pointer is a variance bug.** Sharpen the wording first; inline the material only if sharpening fails.

A pointer does two jobs: say what the material is, and list the **branches** that should trigger reaching it. Every word of an always-loaded pointer costs on every turn.

- Front-load the triggering word.
- One trigger per branch. Synonyms that rename one branch are one branch written twice.
- Cut identity the body already carries.

The house `description` format (a summary, then `Triggers on, <phrases>`) is a trigger list by construction. Write the phrases as things actually typed, not as topics.

## The two loads

Every document and pointer spends one of two budgets:

- **Context load.** Always-loaded material: a `CLAUDE.md` line, a skill description. Spends tokens and attention every turn whether or not it fires. On a 1M premium context this is re-billed per turn, which is the cost the subagent strategy already exists to control.
- **Cognitive load.** The cost on the human: knowing which documents exist and when to reach for each. Not a cost to minimize to zero. It is the price of human agency, so spend it where human judgment matters.

Material behind a pointer escapes context load at the price of the pointer's line. Material with no pointer rides entirely on cognitive load, which is what `skill-finder` exists to recover.

## Information hierarchy

Two content types: **steps** (ordered actions) and **reference** (rules and facts consulted on demand). They mix freely. The decision is where each piece sits on the ladder:

1. **In-file step.** What the agent does, in order.
2. **In-file reference.** Consulted on demand. A flat peer-set (every rule of a review on one rung) is a fine arrangement, not a smell.
3. **Disclosed reference.** Pushed to a separate file behind a pointer, loaded only when the pointer fires. `_refs/` and `references/` in this repo are this rung.

**Progressive disclosure** is the move down the ladder so the top stays legible. Branching is the cleanest test: inline what every branch needs, push behind a pointer what only some branches reach. In a document with steps, undisclosed reference buries them and turns attending to them into a coin flip.

**Co-location** decides what sits beside a piece once it lands: keep a concept's definition, rules, and caveats under one heading rather than scattered.

**Sprawl** is the failure mode: a document simply too long even when every line is live. Attention thins across the excess. The cure is the ladder, plus splitting by branch or sequence.

## Completion criteria

Every step ends on the condition that says the work is done. Two properties make it a lever:

- **Clarity.** Can the agent tell done from not-done? A vague bound ("understanding reached") invites **premature completion**, where attention slips to being done. The visible later steps supply that pull; the criterion's clarity is the resistance. Sharpen the bound first. Only if it is irreducibly fuzzy and the rush is actually observed, split the sequence so the later steps are out of view, and note that hiding works only across a real context boundary (a handoff or a subagent dispatch, not an inline call).
- **Demand.** How much it requires. "Every modified sproc accounted for" forces work that "produce a change list" does not. Demand drives legwork, and it is not step-bound: "every rule applied" binds a body of flat reference the same way.

The strongest criteria are both checkable and exhaustive.

## Leading words

A **leading word** is a compact concept already in pretraining that the agent thinks with while running the document (*lesson*, *fog of war*, *tracer bullet*, *rung*, *frontier*). Repeated as a token, never restated as a sentence, it anchors a region of behavior in the fewest tokens by recruiting priors the model already holds. Coining a new word costs definition tokens that an existing word gives free.

It anchors twice: in the body for execution, in the pointer for invocation. When the same word lives in the prompts, the docs, and the codebase, the material gets reached more reliably.

Hunt for passages that collapse into one token. "Fast, deterministic, low-overhead" becomes *tight*. "A loop you believe in" becomes *red*, a binary observable state.

**Negation is the failure mode beside this lever.** Steering by prohibition drags the forbidden behavior into context and makes it more available, not less: the ban half-reads as an instruction. Prompt the **positive** so the banned behavior is never spoken. A prohibition earns its place only as a hard guardrail that cannot be phrased positively, and even then it gets paired with the positive target.

This one cuts against how the house rules are currently written. Several are correctly stated as bans (authorship, the em dash), because they are guardrails. Others are prohibitions that would read stronger as targets, and `harness:model-upgrade` is where that audit belongs.

## Pruning

- **Single source of truth.** One authoritative place per meaning, so a behavior change is a one-place edit. Duplication costs maintenance and tokens, and inflates a meaning's rank on the ladder past its real one.
- **The environment is a source of truth too** (`package.json` scripts, config files, directory layout, `--help`). A document restating it is a **cache**, earning its load only when the lookup is expensive. Cache what cannot be found by looking: the unwritten convention, the reason behind a choice, the gotcha no config confesses. Leave one-command lookups to the environment, where they cannot go stale.
- **The no-op test.** Does this line change behavior versus the model's default? If not, it pays load to say nothing, and the whole sentence goes, not a few words from it. This is the Bitter Lesson master question in `dotfiles/CLAUDE.md` at sentence resolution: category (c) scaffolding that fails the no-op test is not scaffolding, it is sediment. The test is model-relative, so it gets settled by running the document, not by debate, and settling it is what `harness:model-upgrade` and `harness:skill-feedback` do.
- **Sediment** is the default fate without a pruning discipline: stale layers that settle because adding feels safe and removing feels risky.

## Mechanics

**Invocation.** Two choices, trading the two loads.

- **Model-invoked** (no `disable-model-invocation`): the agent can fire it, and other skills can reach it. The description is a permanent context-load line bought in exchange for discoverability. Required when the agent must reach the skill on its own, or when another skill must.
- **User-invoked** (`disable-model-invocation: true`): zero context load, and the human becomes the index. The `description` turns human-facing, so strip the trigger list.

Reference needed by two user-invoked skills can live in neither: with no descriptions, neither can fire the other. Push it to a plain file both point at.

**Splitting.** By sequence, when the later steps tempt a rush on the one in front. By invocation, when a distinct leading word should trigger it on its own, or another skill must reach it. Each split buys reach and spends a load; make the trade deliberately.

**Router skills.** When user-invoked skills multiply past memory, one user-invoked skill that names the others and when to reach for each converts many things to remember into one. It can only hint, never fire them.

## House additions

- Any category (c) scaffolding carries the annotation: `(scaffold: patches <weakness or cost fact>; added <YYYY-MM>; retest <trigger>)`.
- Model lines belong in the pinned agent definitions and `dotfiles/claude/TIERS.md`, never restated in a skill body.
- Enforcement belongs in a hook, not in emphatic prose. A rule a hook can hold is a rule the prose should stop repeating.
- Run every line through `writing:unslop` before it lands.
