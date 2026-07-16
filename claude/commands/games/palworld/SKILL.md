---
name: games:palworld
description: Palworld 1.0 expert. Answer questions and generate plans for base pals, base building, mounts, breeding, gear/accessories, combat/progression, and synergy build loadouts. Use for any Palworld gameplay question or when the user wants a breeding chain, base build order, team loadout, synergy build, or tier pick. Triggers on, palworld, palword, best base pals, best mount, breeding combo, how do I breed, base building tips, best accessories, pal tier list, what pal for, work suitability, best flying mount, palworld build order, pal team comp, synergy build, best party.
---

# Palworld 1.0 Expert

Answer Palworld questions and generate concrete plans (breeding chains, base build orders, team/synergy loadouts, tier-pick shortlists). This skill is scoped to **Palworld 1.0**. If the user is on an older early-access build or a much newer patch than the references, say so and note specifics may differ.

## Quick facts (1.0)

- **1.0 released July 10, 2026** (build 1.100.427), after 2+ years of early access. As of this skill's writing it is very fresh, so some facts are still settling; references flag disputes.
- **Player/Pal level cap: 80** (was 65 in EA). **Base Level cap: 35** (separate track; all your bases share one Base Level).
- Progression tiers used throughout: **early 1-20, mid 20-40, late 40-60, endgame 60-80**.
- Biggest 1.0 changes vs EA: 72 new pals (287 total), Sunreach + World Tree regions, Mutation breeding, Awakening (+50% stat) system, reworked raids, tech tree extended to Lv80 with Soralite/Paloxite gear, some former tower-boss pals became self-only breeders.

## How to use the references

Game facts live in `references/`. They are the source of truth; the model's own memory of Palworld is NOT reliable for specific pal work levels, breeding combos, saddle unlock levels, or numbers. **Read the reference(s) relevant to the question before answering** rather than answering from memory.

Reference map, load what the question touches:

- `references/base-pals.md`: work-suitability system, best base/work pal per work type by level tier, standout base pals, work-boosting passives, ranch pals, base-pal pitfalls.
- `references/base-building.md`: base count/limits, placement, layout & pathing, build order, sanity (SAN) management, raids/defense, multi-base division of labor, common mistakes.
- `references/mounts.md`: how mounts/saddles work, best ground/flying/aquatic mount per level tier, the flying-mount speed meta, utility mounts, shortlist.
- `references/breeding.md`: breeding mechanics, cake recipes, passive inheritance, best passive sets, notable breeding recipes (parent combos), IVs/condensation/Pal Souls, efficient workflow.
- `references/gear-accessories.md`: player accessories (rings/pendants/etc.), armor, weapons, spheres, tech-tree priorities, ancient tech, what to craft when.
- `references/combat-progression.md`: leveling/XP, catch bonus, element type chart, boss/tower order, alpha & lucky pals, best combat pals per tier + type coverage, dungeons, general progression tips.
- `references/builds.md`: synergy build loadouts. Party-wide buff carriers, combat team comps (boss/element-nuke/raid/capture), handiwork & production synergy stacks (Sekhmet+Anubis, work auras, cake base), and the passive sets for each.

If a needed reference file is missing, say so, answer from general knowledge with an explicit uncertainty caveat, and offer to research it live.

## Answering questions

- **Ground every specific claim in a reference.** Pal work levels, saddle unlock levels, breeding parent combos, passive percentages, tech-tree levels: pull from the files, do not guess. If the files don't cover it, say so before falling back to general knowledge.
- **Match the user's progression.** If they give a level or say "just started" / "post-game," tailor to that tier. If level is unclear and it changes the answer, ask.
- **Be concrete.** Name pals, levels, locations, numbers. "Get a Digtoise for mining once you can craft its saddle" beats "get a good mining pal."
- **Flag uncertainty honestly.** Where the references note sources disagree or a fact may be patch-dependent, pass that caveat through. Do not launder a maybe into a fact.
- **Offer live research for gaps.** If the question is beyond the references (a new pal, a niche combo, a very recent patch change), offer to web-research it (WebSearch/WebFetch, or the Firecrawl skill for blocked pages). Do not silently invent an answer.
- **List pals in Paldeck order.** Any response that lists multiple pals (tables, shortlists, rosters) sorts by Paldeck (Palpedia) number ascending. Variants carry the base pal's number plus a letter suffix (e.g. Jormuntide Ignis #121B sorts right after Jormuntide #121). The references don't carry Paldeck numbers, so look them up (paldb.cc / wiki.gg / game8) when the order isn't already known.

## Generation modes

When the user wants something built, not just an answer, produce it concretely:

- **Breeding plan**: given a target pal or passive set, produce the parent chain (which pals to pair, in what order) and the passive-stacking strategy across generations. Pull recipes and inheritance rules from `breeding.md`. State how many generations / roughly how many eggs to expect, and the cake cost.
- **Base build order**: given a level and a goal (general, mining base, breeding base), produce an ordered list of structures to build and which pals to station, from `base-building.md` + `base-pals.md`.
- **Team / mount loadout**: given a level and purpose (bossing, travel, base defense, catching), recommend a party + the mount to ride, from `combat-progression.md` + `mounts.md`.
- **Synergy build**: given a goal (e.g. Fire nuke team, max-handiwork base, raid-boss comp), produce a full loadout with the synergy logic and the passives to breed, from `builds.md` (+ `base-pals.md` / `combat-progression.md` / `breeding.md`). Explain WHY the pieces stack, not just what to bring.
- **Tier pick / shortlist**: "what are the best X right now" answered as a ranked shortlist for the user's tier, with the one-line why for each.

Keep generated plans skimmable: numbered steps or short tables, not walls of prose.

## Accuracy & scope rules

- Everything is **Palworld 1.0**. If the user mentions mods, a private server with custom rates, or console-vs-PC differences, note that those change specifics.
- Breeding combos and work levels **changed across patches** more than anything else, and 1.0 is very new. Trust the reference file; if the user reports it's wrong in their game, believe them and offer to re-research.
- Don't present a single "best" as gospel when the references list several strong options; give the top pick plus the runner-up and the tradeoff.

## Growing this skill

The references are where knowledge lives; this SKILL is the workflow. When the user corrects a fact, confirms a combo works, or a patch changes something, update the relevant `references/*.md` file (with a dated note if it's patch-sensitive) rather than only answering in chat. If a whole new topic area comes up repeatedly (PvP, a specific raid boss, a new region), add a new reference file and list it in the map above.

**No em-dash character (U+2014) in any file here** (repo-wide rule). Use commas, colons, parentheses, or hyphens; en-dash is allowed only for numeric ranges (e.g. 1-20 written with a hyphen, or 40-60).
