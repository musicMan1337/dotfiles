---
name: vacation:planner
description: Plan a multi-day trip as a staged constraint solve, macro first. Frame and anchors, then region blocks, then day assignment, then clock time. Emits variants that differ by exactly one decision each, scored against a constraint ledger, and keeps the trip's rules in a persistent trip file that grows across sessions. Triggers on, plan the trip, build the itinerary, trip schedule, weekly schedule, work out the days, which day should we do X, move X to Thursday, rearrange the itinerary, does this plan break our rules, add a constraint to the trip, compare the plans, vacation planner, /vacation:planner.
---

# vacation:planner

The deliverable is a **schedule you can defend**, not a pretty day list. Every day in the output traces back to a stated constraint, and every stated constraint has a visible verdict against every variant.

Sibling skill: `vacation:flights` books the getting-there. This one spends the days.

## Trip file

State lives at `~/.claude/vacation/trips/<slug>/trip.md`, outside the dotfiles repo because that repo is public and travel plans are not. Create the directory on first run.

Read it before doing anything. It is the single source of truth for the frame, the anchors, and the rules; a schedule is a rendering of it, never the record itself. Most sessions add one constraint and re-solve, so the file grows and the solve gets cheaper over time.

```markdown
# <Trip name>

## Frame            <- given facts, stage 1
## Anchors          <- time-locked commitments, stage 2
## Rules            <- meta-constraints, hard and soft, stage 3
## Wants            <- unscheduled content, grouped into clusters
## Open questions   <- what the next session has to settle
## Decided          <- settled choices with the reason, so they stop getting relitigated
```

When the user states something new, write it into the file **before** re-solving. A constraint that only lived in the conversation is gone next session.

## The stages

Run them in order, macro to granular. Do not start a stage until the previous one's criterion is met; a day-level plan built on an unsolved region shape is wasted work.

### 1. Frame

The immovable box: dates, entry and exit port with real times, party, budget ceiling, lodging or tickets already bought.

Tag every number **given** or **derived**, and show the derivation for derived ones inline.

```
Depart NRT Sat Nov 28, 15:40                    (given)
At NRT by 13:40                                 (derived: 2h intl check-in)
Leave Osaka by ~08:45                           (derived: 13:40 - 2h30 Nozomi - 1h N'EX - 30m transfers - 45m slack)
```

A derived number that gets restated as a constraint is how a plan quietly optimizes against a fact nobody checked.

**Criterion:** every clock value in the frame is labeled, and no derived value is missing its arithmetic.

### 2. Anchors

Anything time-locked. Each anchor needs four fields, and the third and fourth are the ones default planning drops:

- **Where** (which region)
- **Clock** (fixed times within the day)
- **Allowed days** as a *set*, not a single day. "Monday or Thursday or Friday" is the constraint; picking one is a stage-4 decision.
- **Span**: how many consecutive days it occupies. An evening-plus-overnight-plus-next-morning commitment is a **2-day span**, not a day. Sizing it as one day is the most common way a plan comes out infeasible without anyone noticing.

Note weight where the user gave one (a birthday, a booked ticket). Weight breaks ties in stage 4; it does not make a soft anchor hard.

**Criterion:** every anchor has all four fields, and every multi-day span is written as a span.

### 3. Rules

Meta-constraints the user carries into the trip. Split them:

- **Hard**: a variant that breaks one is not a variant, it is a rejected candidate. Say so out loud rather than shipping it as an option.
- **Soft**: pacing, energy, "no two heavy transit days back to back", "don't change hotels more than N times". These get graded in the ledger, not enforced.

Rules about *shape* (how many region crossings, how many hotel bases) belong here and drive stage 4. Rules about *feel* (mornings slow, one rest afternoon) belong here and drive stage 6.

**Criterion:** each rule is classified hard or soft, and each hard rule is stated as something checkable against a day list.

### 4. Region blocks

Solve the coarse shape before any day gets an activity. This is the stage that collapses the search space, and skipping it is why default itineraries differ in four dimensions at once.

Assign each day a **region**, nothing more. When the trip has multiple regions plus a crossing rule, read `references/region-blocking.md`: the crossing count usually *forces* the block structure, so the only real choice left is how many days each block gets.

Output a small table of candidate block partitions, not one answer.

**Criterion:** every candidate accounts for all N days, satisfies every hard shape rule, and places every anchor inside a block of the right region on a day inside its allowed set.

### 5. Day assignment

Fill blocks with clusters. A **cluster** is content grouped by geography, not by category: the things you can do on foot from one station. Clusters are the unit that moves between days; individual wants are not.

A crossing day is not a full day. Charge its transit hours to one side and plan the remainder honestly.

**Criterion:** every want in the trip file is either placed on a day or listed as cut, with nothing silently dropped.

### 6. Clock

Hour level, and only for the variant the user is converging on. Real transit durations, opening hours, meals, buffers. Cache each transit leg's duration in the trip file so the next session does not re-look-it-up.

**Criterion:** every travel leg has a duration and a slack figure, and every anchor's arrival time is shown to be reachable from the thing before it.

## Variants

**One decision per variant.** A variant is named by the decision it makes, and it differs from its sibling in that decision alone.

Default planning produces plans that change the anchor day *and* the routing *and* which attraction got cut, all at once. Then nothing can be attributed and the user is comparing vibes. When two decisions genuinely interact, say so and hold one fixed while showing the other's effect.

Name variants by the decision, not by a letter: "Sailor Moon Monday, 4 Kansai days" beats "Plan A".

Cap it at four. More than that means an earlier stage was left unsolved.

## Ledger

Every variant gets scored against every rule and anchor, as a table, before any prose:

| Constraint | Kind | Variant 1 | Variant 2 | Variant 3 |
|---|---|---|---|---|
| cross regions exactly twice | hard | pass | pass | pass |
| anchor on allowed day | hard | pass | pass | **break** |
| no back-to-back transit days | soft | pass | strain | pass |

Three verdicts only: **pass**, **strain**, **break**. A `break` on a hard rule disqualifies the variant; keep it in the table anyway so the user sees what the rule is costing them. Prose "watch out for" notes are not a ledger; they let a violation read as a flavor note.

Then one recommendation, in two sentences, naming what it trades away.

## Render

Write a self-contained HTML file to `~/.claude/vacation/trips/<slug>/schedule.html` and print the path. Do not open it.

If the trip already has a `schedule.html`, extend its stylesheet rather than redesigning; a trip's look is continuity the user navigates by. For a trip's first page, load `artifact-design`.

The ledger renders as a real table, the variants as tabs, and each day carries its region and its transit load. Offer to publish as an Artifact only if the user wants to share it.

## Gotchas

- **A derived number wearing a constraint's clothes.** "At the airport by 1pm" with no departure time behind it silently disqualified a whole plan shape. When a plan is rejected for tightness, re-derive the number that made it tight before accepting the rejection.
- **Span anchors sized as days.** Overnight commitments (a park you sleep inside, a ryokan, a night train) occupy an evening, a night, and a morning. Booking them as one day makes the arithmetic come out one day short somewhere else, usually far from the cause.
- **Allowed-day sets collapsed too early.** Fixing an anchor to one day in stage 2 hides the variants that stage 4 exists to find. Carry the set.
- **Crossing days counted as full days.** A 5-hour transit day is roughly a half day of content on one side and nothing on the other. Blocks that look balanced by day count are often not.
- **"Once each way" is not "one crossing".** Confirm the count. Pass-through transfers are a separate question from stays; ask whether changing trains in a region counts as being there.
- **Cutting content is a decision, not a side effect.** When a variant has no room for a cluster, name the cut in the ledger. A cluster that quietly vanishes between variants is the thing the user notices last and minds most.
- **A whiteboard dump is a want list, not a cluster list.** Items arrive grouped by city, but days are built from things walkable from one station. Regroup by geography before counting days, or a city that looks like one day turns out to be three.
- **The trip file drifts.** After the user accepts a change, write it to `## Decided` with the reason. Otherwise the same tradeoff gets re-argued next session from scratch.
