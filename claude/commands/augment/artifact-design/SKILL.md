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
11. **Every word on the page runs through `writing:unslop`.** Invoke that skill
    and write the copy clean as you draft it. Design tokens defeat the visual
    tell; unslop defeats the prose tell. Both or neither.

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

## Required page furniture (every artifact)

Two elements ship on **every** artifact, whatever the type:

**1. Theme toggle button.** `mammoth.css` wires light + dark in both directions
(`[data-theme]` overrides plus a `prefers-color-scheme` default), so a button that
flips `data-theme` on `:root` works with zero extra CSS. Put a pill button at the
top-right of the masthead/header, and the flip script once before `</body>`.

CSS (semantic tokens only):
```css
.themebtn{flex:none;font-family:var(--mm-font-mono);font-size:.7rem;letter-spacing:.08em;text-transform:uppercase;background:transparent;color:var(--mm-text-muted);border:1px solid var(--mm-border-default);border-radius:9999px;padding:6px 14px;cursor:pointer;transition:color .15s var(--motion-easing-standard),border-color .15s var(--motion-easing-standard)}
.themebtn:hover{color:var(--mm-text-default);border-color:var(--mm-border-emphasis)}
```

Markup (in the header, opposite the title):
```html
<button class="themebtn" id="themeToggle" type="button" aria-label="Toggle light/dark theme">Theme</button>
```

Script (seeds from the OS preference on first click so the first toggle always
flips visibly):
```html
<script>
(function(){
  var b=document.getElementById('themeToggle'),r=document.documentElement;
  b.addEventListener('click',function(){
    var c=r.getAttribute('data-theme');
    if(!c)c=window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';
    r.setAttribute('data-theme',c==='dark'?'light':'dark');
  });
})();
</script>
```

The viewer's own theme control also stamps `data-theme` on `:root`; because
mammoth wires both directions, that path keeps working alongside this button.

**2. Prepared date, top of page.** Every artifact shows the date it was prepared,
in the masthead metadata near the eyebrow/title (not buried in a footer). Real
date, format `YYYY-MM-DD`, in the mono/muted meta style:
```html
<div class="meta"> ... <span>2026-07-21</span> ... </div>
```
Take the date from the current environment (the session's "Today's date"), never
guess. If the masthead already carries other metadata (source, counts), the date
is just one more `<span>` in that row.

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

## Register in the artifacts manifest (on every publish)

Every artifact is tracked in the Obsidian manifest at
`/Users/derek/eBacon/obsidian/eBacon/Artifacts Manifest.md`. That file is the **source of
truth**; Derek rebuilds the Excel tracker (`~/dotfiles/artifacts/artifacts-manifest.xlsx`)
from it. Whenever you publish (call the `Artifact` tool), update the manifest in the same
turn:

- **New artifact (new URL):** append ONE row to the table between the
  `<!-- artifacts:start -->` and `<!-- artifacts:end -->` markers. Column order:
  `Group | ID | Title | Type | Status | Rec | Location | Updated | Link | Local file | Description | Notes`.
  - `Group`: the closest existing content group already in the table, or a short new one.
  - `ID`: next `P<n>` after the highest `P` number already present (use `L<n>` if it will stay local-only).
  - `Status`: `Current`. `Rec`: `✅ Keep`. `Location`: `Published + Local`. `Updated`: today's date (`YYYY-MM-DD`, from the environment).
  - `Link`: `[open](<artifact url>)`. `Local file`: the `` `<slug>.html` ``. `Description`: one concrete sentence (what it contains). `Notes`: `distinct`, or the id it overlaps / supersedes.
- **Updated artifact (same URL/file):** edit that artifact's existing row (`Updated` + `Description`); do NOT add a duplicate row.
- Bump the `> Last updated:` line and the header counts.
- Keep every cell em-dash-free (house rule): use `-`, `:`, `(`, `)`, `;`. Escape any literal `|` as `\|`.
- If the manifest file is missing, create it with the `> Last updated` line, a `# Artifacts Manifest` heading, the two markers, and a header + separator row, then append.

## Build checklist

- [ ] Built locally to `artifacts/<slug>.html` and previewed (`open`) BEFORE publishing
- [ ] Inlined `mammoth.css` into the artifact `<style>`
- [ ] All colors via `--mm-*` tokens; accent ≤5% of the view
- [ ] Serif display + humanist sans; `text-wrap: balance` on headings; 68ch measure
- [ ] Per-property transitions on the standard easing; reduced-motion respected
- [ ] One signature texture, applied consistently
- [ ] Theme toggle button (pill, top of masthead) + flip script before `</body>`
- [ ] Prepared date (`YYYY-MM-DD`, from the environment) in the masthead metadata
- [ ] Empty/error/loading states designed, not default
- [ ] Nothing from the exclusion list present
- [ ] Copy run through `writing:unslop` (rules 24, 25, 27 are the ones that bite)
- [ ] Row appended/updated in the Obsidian artifacts manifest (source of truth for the Excel tracker)
