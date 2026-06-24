---
name: augment:artifact-design
description: Personal augmentation layer for the built-in `artifact-design` skill. Runs in tandem with (never instead of) the base `artifact-design` skill, grounding every artifact in the mammoth-ui "Warm Editorial" design system: a self-contained CSS token spec plus hard design principles that defeat the recognizable AI-slop look. Auto-paired with `artifact-design` by the augment-skill PreToolUse hook.
---

# augment:artifact-design

Augmentation layer for the built-in **`artifact-design`** skill. The base skill
supplies the design *process* (brainstorm tokens, critique, build, re-critique)
and general taste. This layer **replaces the palette/type/motion freedom with a
fixed house system** so artifacts read as Derek's, not as generic AI output.

## How this runs

Not standalone. The `augment-skill` PreToolUse hook fires whenever the base
`artifact-design` skill is invoked and tells you to load this one in tandem. The
base skill still runs; this layer constrains and overrides its open choices.

> Part of the `augment:<cc-skill>` set: each `augment:*` skill enhances one
> built-in Claude Code skill of the same trailing name without modifying the
> bundled original (which lives in the app bundle and is wiped on every update).

## The mandate: use mammoth, don't reinvent

The base skill says to brainstorm a fresh palette and commit it. **Override that:
the palette is already decided.** The design system lives next to this file:

- **`mammoth.css`** — the full "Warm Editorial" token spec as standalone, plain
  CSS (no Tailwind, no build step). Read it and **inline the whole thing** into
  the artifact's `<style>`, then build every color / type / motion / shape
  decision off its tokens.

When the base skill prompts for a `<palette_commit>`, fill it from mammoth
families instead of inventing hexes:

```
<palette_commit>
frame:  warm editorial / mammoth-ui
ground: oklch(97% 0.012 87)   /* --mm-surface-default (ivory-50) */
text:   oklch(21.5% 0.01 45)  /* --mm-text-default (ink-900) */
accent: oklch(62% 0.14 42)    /* --mm-accent-default (clay-500) */
accent-2: oklch(66.8% 0.115 155) /* --mm-secondary-default (moss-500) */
</palette_commit>
```

Reference **semantic tokens** (`--mm-*`) in your rules, never the raw
`--color-*` primitives.

## Principles (apply on top of the base skill)

1. **Accent restraint.** The clay accent appears on **≤5% of any view**. Most of
   the page is warm ivory surface + ink/sand text. An accent everywhere reads as
   a template.
2. **Warm everything, never pure.** Backgrounds and text come from the warm
   ramps (ivory/ink/sand). **Never `#fff` or `#000`,** never a cool gray.
3. **Editorial type pairing.** Serif display (`--mm-font-display`) + humanist
   sans body (`--mm-font-body`). **Never Inter or system-ui as the sole face.**
4. **Heading craft.** `text-wrap: balance` on every heading. Negative tracking at
   display sizes (`--mm-tracking-display`). Tight display leading (~1.05).
   Hierarchy via **size AND opacity/color tier**, not weight alone. Aggressive,
   not gradual, size jumps. Cap body measure at `--mm-measure` (68ch).
5. **Off-grid spacing as a human tell.** Prefer the `--mm-space-*` scale
   (5/9/14/22/35…), not a mechanical 8px grid. Asymmetric section padding (e.g.
   more top than bottom) reads as authored.
6. **Color discipline (OKLCH).** Clay = primary interactive. Moss = brand, **not
   success**. Feedback colors (sage/amber/ember/slate) are for feedback only.
   Slate is deliberately the only cool tone, reserved for info.
7. **Motion is per-property, never `transition-all`.** `--motion-easing-standard`
   `cubic-bezier(0.2,0,0,1)` is the workhorse (not `ease-in-out`). Entrances get
   playful overshoot (`--motion-easing-emphasized`); exits are decisive, no
   bounce (`--motion-easing-exit`). Opacity always tweens. One orchestrated
   moment beats scattered effects. Respect `prefers-reduced-motion` (already in
   `mammoth.css`).
8. **The single weird texture.** Pick ONE signature detail and apply it
   consistently: the hard-offset shadow (`--mm-shadow-hard`), a dotted hover
   border, or a subtle grain. Use it on one element type. Don't also pile on soft
   shadows. This fingerprint is what makes the page unmistakable.
9. **Design the dead zones.** Empty / error / loading / zero states get real
   copy and personality, not a spinner. Personality lives in the structural gaps.
10. **Icons (if any): Phosphor-style, light weight.** ~1–1.5px stroke at 24px,
    round caps/joins, `currentColor`, editorial metaphors. Generate decorative
    graphics with Canvas, not hand-authored SVG paths.

## Hard exclusion list — NEVER do these

- Inter / system-ui as the sole typeface
- Blue or indigo as the accent (this is the dead-giveaway AI default)
- `transition: all` / `duration-300 ease-in-out`
- The default `rounded-lg + shadow-md` card
- Pure `#fff` / `#000`, or any cool-gray neutral
- Shipping a component without a designed empty/error/loading state
- Uniform padding across every section
- Uncustomized shadcn/library defaults
- The hero → features → testimonials → CTA template layout
- A vivid accent used on more than ~5% of the view

## Fonts in CSP-sealed artifacts

Artifacts **cannot load CDN/Google fonts** (the CSP blocks all external hosts,
fonts included). To ship the real faces, paste base64 `@font-face` blocks into
the FONT EMBED SLOT at the top of `mammoth.css`; the stacks already name those
faces first, so an embed wins automatically. Until then, the warm humanist
system fallbacks render, which still honor the serif-display + sans-body intent.

## Preview before publish (DEFAULT)

Never publish to claude.ai as the first step. Always render a local preview and
get explicit approval first.

1. **Write** the artifact (Artifact-content form: starts with `<title>`/`<style>`,
   no `<!doctype>`/`<html>`/`<head>`/`<body>` of your own) to:
   `/Users/derek/dotfiles/artifacts/<slug>.html`
   (`mkdir -p` the dir first; it's gitignored, local-only).
2. **Open** it in the browser for review:
   `open "/Users/derek/dotfiles/artifacts/<slug>.html"`
   Fidelity note: this file is publish-ready as-is. The claude.ai wrapper only
   adds `color-scheme:light` + a tiny body reset that `mammoth.css` already
   supersedes, so the local preview matches the published artifact closely.
3. **Approve** via numbered options, e.g.:
   1. Publish as artifact
   2. Make changes (describe)
   3. Keep local only, don't publish
4. **Publish only on approval**: call the `Artifact` tool with that same file
   path. Iterate on the local file (re-`open` to re-preview) until approved.

## Build checklist

- [ ] Built locally to `artifacts/<slug>.html` and previewed (`open`) BEFORE publishing
- [ ] Inlined `mammoth.css` into the artifact `<style>`
- [ ] All colors via `--mm-*` tokens; accent ≤5% of the view
- [ ] Serif display + humanist sans; `text-wrap: balance` on headings; 68ch measure
- [ ] Per-property transitions on the standard easing; reduced-motion respected
- [ ] One signature texture, applied consistently
- [ ] Empty/error/loading states designed, not default
- [ ] Nothing from the exclusion list present
