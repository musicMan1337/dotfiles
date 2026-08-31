# Region blocking

How to solve stage 4 when a trip has multiple regions and a rule about crossings. The point is that the shape is usually **derived, not chosen**: get the derivation right and the candidate set drops from hundreds of day-orderings to a handful of block sizes.

## The walk

Treat the trip as a walk over regions. Consecutive days in the same region form a **block**; a **crossing** is the boundary between two adjacent blocks.

Two facts do most of the work:

- **Blocks = crossings + 1.** A rule like "cross between the two areas once each way" means two crossings, which means exactly three blocks. Not a preference, arithmetic.
- **The first and last block are forced to the entry and exit region.** You land where you land. If entry and exit share a region and the crossing count is even, the walk is a palindrome in region terms.

Together these often fix the entire structure. Entry and exit at the same port, two crossings, two regions gives exactly one shape:

```
[ Home region ] [ Other region ] [ Home region ]
      n days         k days           m days
```

The only remaining freedom is `n + k + m = D`. That is a composition of D into 3 parts, which for a week is a couple dozen candidates before pruning, and far fewer after.

**Check the count with the user.** "Once each way" and "one crossing" differ by a factor that changes everything. So does whether a pass-through transfer counts as visiting a region: routing through a hub to reach the far side may or may not spend a crossing under the user's intent. Ask.

## Pruning with anchors

Each anchor cuts the candidate set hard:

- An anchor in region R with allowed-day set S forces at least one day of S into an R block. Since block positions are contiguous, this pins a bound on the earlier blocks' combined size. An anchor allowed only on day 3 in the home region forces `n >= 3` when the first block is home.
- A **span** anchor of length L needs L consecutive days inside one block, so that block needs `k >= L`, and more if the span cannot sit at the block's edge (a place you must travel to and from wants interior days, or a neighbor day that absorbs the travel).
- Anchors in different regions on nearby days are the usual source of infeasibility. Two anchors 1 day apart in different regions require a crossing between them, and the crossing has to fit in the calendar and in the day.

## Charging the crossing

A crossing day is not a full day on either side. Decide which side pays:

- Morning crossing: the day belongs to the destination block, minus the transit hours.
- Evening crossing: the day belongs to the origin block, and the destination gets a night only.

Write the charge explicitly in the candidate table, because two candidates with identical day counts can differ by a full day of usable content depending on which way the crossings are charged. Count **usable half-days**, not calendar days, when comparing.

## Ranking candidates

Once the feasible set is small, rank on things the user can feel:

1. **Usable half-days in the block holding the most wanted content.** The block with more clusters should get more days; this is the tradeoff that actually decides the trip.
2. **Hotel changes.** Each one costs a morning and an evening. It is the cost users underestimate most.
3. **Worst single transit day.** One 5-hour rail day is worse than two 2.5-hour days for most people; ask rather than assume, since some prefer a single push.
4. **Slack on the exit day.** How much buffer the last day has against the departure. This is the only one where being wrong is expensive.

Present as a table with those columns, one row per candidate, before assigning any activity. The user picks the shape; then stage 5 fills it.

## Backtracking through a hub

When no direct route exists between two regions, the trip may pass back through the origin region to reach the far side. This is a real cost (hours) but usually not a crossing (no stay). It shows up in ranking as a bad "worst single transit day", which is where it belongs. Flag it explicitly: a long haul that reads as one line in an itinerary can be five hours of trains, and the user should be choosing it knowingly.
