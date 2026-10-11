---
name: 8bit:stage-plot
model: sonnet
description: Generate a stage plot / tech rider for 8 Bit Mammoth as a self-contained HTML artifact (stage grid + input list + monitor mixes + stage requirements). Use when the user wants a stage plot, input list, or tech rider for a booking. Triggers on, stage plot, stageplot, stage layout, tech rider, input list, channel list, where does everyone stand, monitor mixes, plot for the gig, make a stage plot, 8 bit mammoth stage plot.
---

# 8 Bit Mammoth Stage Plot

Produce a stage plot as a single-file HTML artifact: a positional stage grid plus the technical data a sound engineer needs (input list, monitor mixes, stage requirements). Output is published via the Artifact tool and is printable to a one-page PDF.

## Assets: start here every run

- **`template.html`** (this folder): the bare-bones shell. It carries the complete design system (color tokens for both themes, pixel-block tiles, the print stylesheet) with placeholder body content and `FILL:` comments. **Copy it and fill it in; do not rebuild the CSS from scratch.**
- **`~/dotfiles/artifacts/8bit-stage-plot.html`** (repo `artifacts/`): a fully worked 8-piece example. Read it to match quality and see every component populated. It is the reference output, not a file to overwrite. (Referenced by absolute path because `artifacts/` sits outside the symlinked `commands/` tree; if the repo isn't at `~/dotfiles`, `template.html` alone is enough to work from.)
- Load the **`artifact-design`** skill before writing (the `augment:artifact-design` hook pairs its house design layer automatically). The template already embodies those choices; artifact-design is the tie-breaker for anything the template doesn't cover.

## Read for band facts

Read only what the booking needs, then ground instrumentation in it:

1. `../references/configurations.md`: maps group size (small 5–8 / mid 10 / large 12+) to instrumentation. This drives how many tiles, chips, and channels.
2. `../references/band-overview.md`: the band's identity and source of truth for facts.

Do not invent roster names, gear, or venues. If the user hasn't given a detail and it isn't in the references, ask or leave it as a fillable blank.

## Intake: ask before building

Use AskUserQuestion for real choices; ask plainly for one or two missing facts.

- **Configuration for this booking.** Small (5–8), mid (10), large (12+). Sets instrumentation and channel count.
- **Roster and positions.** Which instruments, and where they stand. If the user gives an ASCII/rough layout, honor it exactly (that is the fastest, least-ambiguous input). Otherwise propose a standard layout and confirm.
- **Special gear** worth flagging to an engineer (e.g. a player's own kick mic, wireless horns, stereo keys). These become `detail` tags and input-list footnotes.
- **What to include.** Full rider (plot + input list + monitors + requirements) is the default. The user may want plot-only.

Don't ask about the design look; it's fixed by the template.

## Building the plot

Copy `template.html` to a working file, then fill it following the `FILL:` comments. Key rules:

- **Stage orientation is VIEW FROM AUDIENCE.** This is the one thing that reliably goes wrong. On the page, **left = performers' Stage RIGHT, right = Stage LEFT** (SL/SR are always from the performer's perspective facing the crowd). Every `(SL)`/`(SR)` tag on a tile and every `SL`/`SR` in the Power line must agree with where the tile sits on the page. Cross-check them before publishing.
- **Grid:** 12 columns, one `grid-row` per physical row (back = row 1). Place tiles with inline `grid-column`. Spread a horn line evenly across the front row.
- **Color = section, not decoration.** `.rhythm` (cyan) for drums/bass/guitar/keys; `.horn` (amber) for brass/reeds. The legend and input-list dots use the same mapping.
- **Input list:** one channel per row, numbered; `dot c` for rhythm sources, `dot a` for horns. Put special-gear callouts in a `<p class="note">` footnote with a `*` marker.
- **Keep the disclaimer verbatim.** It sets expectations that the rider is a reference, not a demand.
- **No em-dash characters or `&mdash;` entities** anywhere in the file. Use `:`, `;`, `,`, or `()`. En-dash `&ndash;` is allowed only for numeric ranges (e.g. channel `1&ndash;7`).

## Output and print

1. Write the filled file (scratchpad or a path the user names), then publish with the Artifact tool. Favicon 🎺, title `<Band> &middot; Stage Plot`.
2. Tell the user how to print: **Ctrl+P → Save as PDF**, with **Background graphics ON** (renders the colored borders/tint) and **Headers/footers OFF** (frees vertical space). The print stylesheet forces a light ink-friendly palette and scales the sheet to land on one portrait page.
3. Offer follow-up adjustments as numbered options.

## Growing this skill

When the band's real setup firms up (final roster, standard input list, actual stage-size minimums, recurring special gear), fold those defaults into `template.html` so future plots start closer to done. Design-preference changes (the band has already asked to drop grid lines, stage fill, and any blinking cursor) belong in the template's CSS/markup. Band facts belong in `../references/`.
