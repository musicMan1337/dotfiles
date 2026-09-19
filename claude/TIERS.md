# Model Tier Policy (single source of truth)

Semantic tiers, mapped once here. Skills and agents reference tiers by the
floating Anthropic aliases (`haiku` / `sonnet` / `opus`), which track the
newest model in each tier; a same-tier model release requires no edits
anywhere.

| Tier | Alias | Use for |
|------|-------|---------|
| CHEAP_LOOKUP | `haiku` | pure search/lookup/log reading, mechanical steps (commits, file ops) |
| MID | `sonnet` | read + classify/label fan-outs, light judgment at volume |
| DEEP | `opus` | planning, synthesis, correctness-critical review |
| SESSION | (inherit) | only when the task genuinely needs the main session's model |

Where assignments live:

- **Agents**: frontmatter `model:` in `claude/agents/*.md` (deployed to `~/.claude/agents/`). This is the enforcement surface; the subagent-gate builds its deny message from it at runtime.
- **Skills**: frontmatter `model:` per skill. Assignments are judgment calls about the task, not facts; when in doubt, prefer the cheaper tier and promote on observed quality misses.

Maintenance rule (re-measure trigger): tier ASSIGNMENTS are a price/capability
snapshot. On each new model generation, re-check the two dated assumptions:
(1) price ratios between tiers; (2) which task classes the cheap tier now
handles well (each generation moves tasks down a tier). Do not encode per-task
model rationale prose anywhere else; it rots.

Measured 2026-09 (per MTok, input/output): opus $5/$25, sonnet $2/$10, haiku
$1/$5. Haiku-to-opus is 5x, not the ~30x that held in 2026-07, and sonnet-to-opus
is 2.5x. Tier routing no longer pays for itself on price alone at small volumes;
the standing reason to delegate is context hygiene (see "Subagent Strategy" in
CLAUDE.md), and the cheap tiers earn their place on high-volume fan-out.
