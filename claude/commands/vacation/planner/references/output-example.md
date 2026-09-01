# Worked example: the output a finished solve produces

Drawn from a nine-day Japan trip solved over one long session, Aug-Sep 2026. The trip file itself stays outside this repo; what is kept here is the shape of the deliverable and the mistakes the session actually made.

## What the page contains, in order

1. **Masthead**: prepared date, trip window, entry and exit with real times, total want count.
2. **Settled banner**: the decision, and the one or two facts that decided it. Two short paragraphs, not a summary.
3. **Tabs**: the locked plan first, marked `LOCKED`; rejected candidates kept as `ALT 01..n` so the reasoning stays inspectable.
4. **Category legend** plus the encoding switch.
5. **Per variant**: title, deck, a stat row, a one-line statement of what it cuts, then the calendar.
6. **Calendar**: one card per day in a `repeat(auto-fit, minmax(318px, 1fr))` grid. Card = weekday + date, region chip, a headline naming the day's job, then the time rail.
7. **Constraint ledger** across all variants, with diverging rows auto-marked.
8. **Check before booking**: the open questions and the facts that need confirming.

## The time rail

Rows are `[time, activity, category, locked?]`. Two-column grid, mono tabular times, a dot per row carrying the category colour.

**Draw the connector downward from each dot and suppress it on `.rail > div:last-child`.** A single full-height line on the rail container will run into any note rendered below the rows. Notes are siblings of the rail, never grid children.

## Category colours

Adopt the traveller's own colour code when they have one. This trip's source was hand-drawn in five pens: Entertainment, Food, Hotels, Shopping, Transportation. Four map onto the mammoth ramps (ember, moss, slate, amber); shopping needs one extra token since the system has no violet.

Small coloured dots tested badly for legibility. Offer the encoding as a switch (tint, bold text, coloured times, underline, dots) and let the traveller pick; weight does more work than hue at 14px. The tint wash won here, and it happened to match the pen-on-paper original.

## Verify the page against its own data

Prose drifts from the schedule the moment a day changes. Every claim outside the cards that could be checked, was, by running the page's own `VARIANTS` array in a Node vm and asserting:

- every variant covers the exact expected date list
- times run monotonically forward inside each day
- every row carries a valid category
- each want in the canonical list resolves to a row, per variant
- day spans derived from the data match the numbers used in the prose
- venue closing times are cleared by the slots assigned to them
- ledger rows all have the same width, and column order matches variant order

This caught a shipped claim that Sunday was the longest day when it was mid-pack, an invented "twelve named meals" count, and a variant advertising full coverage while missing two anchors.

## What went wrong, in order

- **A derived number wearing a constraint's clothes.** Three plans optimised against "at the airport by 1pm" with no departure time behind it. The real time was 15:40, which un-killed an entire trip shape.
- **The want list arrived in three layers**: a whiteboard, then a handwritten day grid, then corrections. Plans built on layer one satisfied every constraint they knew about, which made them unfalsifiable rather than merely incomplete.
- **Two named wants were one event, twice.** "Shinjuku Ale photoshoot" was the Sailor Moon photoshoot; "Attack on Titan" was the night walk. Both were scheduled twice, inflating two days.
- **A venue's category is not guessable from its name.** "Fushimi Sake Village" reads like a daytime museum and is an 11:00-22:00 hall with nine kitchens. Looking it up moved Kyoto to the end of the whole trip.
- **Closing times ordered the days, not travel time.** Nishiki 18:00, a shrine store 17:00, a castle 16:00, a temple office mid-afternoon, sunset 16:45.
- **The traveller's own reordering beat the solver's.** They inverted a Kyoto day to run north to south and removed thirty minutes of backtracking that had been designed in.
- **An inherited document carried unsourced content.** Four locations reached the schedule from a starting HTML rather than from either list, one of them just the district the hotel was already in.
