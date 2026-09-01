---
name: vacation:plan-optimizer
description: Verify a planned itinerary against reality before anything is booked. Takes a vacation:planner output and checks every approximation in it, real venue hours and last admission, actual timetables door to door, date-specific closures, holidays and sunset, then reports what breaks ranked by consequence and emits a pre-trip checklist ordered by when each booking window opens. Reports, never edits. Triggers on, check the itinerary, verify the plan, are these times realistic, will this actually work, pressure test the trip, look up the real hours, check the trains, is this schedule feasible, what do I need to book, booking checklist, reservations I need to make, tickets I need in advance, optimize the itinerary, tighten the plan, /vacation:plan-optimizer.
---

# vacation:plan-optimizer

`vacation:planner` builds a schedule out of estimates. This one finds out which estimates were wrong, and what that costs.

The deliverable is two things: **findings ranked by consequence**, and **a checklist ordered by when each booking window opens**. Both are useless without the other; a plan that survives verification but misses a reservation window is still a lost trip.

## The boundary

**This skill reports. It does not edit the itinerary.** Findings go back to `vacation:planner`, which owns the schedule and the constraint ledger. Keeping the split means a verification pass can be run twice and give the same answer, and a plan change always goes through the solver that knows the constraints.

The one thing it does write is verified facts into the trip file, replacing estimates with real numbers so the next solve starts from ground truth.

## Inputs

The planner's trip file at `~/.claude/vacation/trips/<slug>/trip.md` plus its schedule. If a plan arrives some other way, ask for the trip file, or reconstruct the frame and anchors from what you were given before verifying anything: a finding with nothing to compare against is trivia.

Also establish **today's date and the traveller's home timezone**. Both are load-bearing later.

## A fact is only a finding once it meets the plan

Report every verified fact against the slot it lands in, never on its own.

```
weak    Nishiki Market closes at 18:00.
strong  Nishiki is scheduled 16:45 to 17:45; it closes 18:00; clears by 15 minutes.
strong  Fushimi Castle is scheduled 17:10; last admission 15:30, gates 16:00; MISSED, grounds only, and after dark.
```

An hours page pasted into a report is a lookup, not a check. The comparison is the entire job.

*(scaffold: patches the model's habit of returning researched facts in a neutral list and leaving the plan-versus-fact arithmetic to the reader; added 2026-09; retest when a model volunteers the slot comparison and the verdict unprompted)*

## Verdicts

Every checkable claim in the plan gets exactly one:

- **Verified**: confirmed against a source, with the source and the date you checked it.
- **Corrected**: the plan's number was wrong; give the real one and what it costs.
- **Unverifiable**: no authoritative source exists. Say so plainly, name the fallback, and treat it as a risk rather than quietly keeping the estimate. Rural buses, small shops and seasonal hours live here.

"Probably fine" is not a verdict. An unverifiable fact that gets reported as verified is worse than one nobody looked up, because it stops anyone else from checking.

## Passes

Run in order. Each pass can invalidate the work of later ones, which is why the cheap broad ones come first.

### 1. Inventory

Pull every checkable claim out of the plan: transit legs and their durations, venues with hours, anything requiring a ticket or reservation, and every hard-timed anchor. Nothing is researched yet.

**Criterion:** every row in the schedule carrying a time or a place appears exactly once in the inventory.

### 2. Date-specific facts

Not typical hours: these dates. Public holidays, weekly closing days, seasonal timetables, off-season attractions, event blackouts, and sunset. This runs first because one holiday can invalidate a whole day and the lookups are cheap.

**Criterion:** every travel date has been checked for holidays and seasonal changes, and sunset is recorded for any day with an outdoor evening item.

### 3. Venues

Hours, weekly closure, and **last admission**, which is a different number from closing and is where plans usually die. Note whether entry is timed or reserved, and whether the on-site shop keeps shorter hours than the site.

**Criterion:** every venue with a slot has its closing time, its last admission, and its closing day confirmed or marked unverifiable.

### 4. Transit, door to door

Real timetables for the actual day and time, not a generic duration. A leg is measured from where you actually are to where you actually need to be:

```
hotel to station        walk, with luggage if it is a checkout morning
platform transfer       real interchange time at that station
station to venue        walk at the far end
```

Also capture **frequency** and **last service**. A 40-minute leg running hourly carries more risk than a 70-minute leg running every ten, and anything ending late needs its return leg verified rather than assumed.

**Criterion:** every leg has a door-to-door figure, a frequency, and, for anything after 21:00, a confirmed last service.

### 5. Recompute

Feed the corrections back through the schedule and see what actually breaks. A corrected number is not a finding until you know what it costs downstream: a leg that grew by 25 minutes either eats slack, misses an anchor, or does nothing at all.

**Criterion:** every Corrected verdict has its downstream effect stated, including the ones whose effect is none.

### 6. The booking clock

See below. Runs last because verification decides what actually needs booking.

## Ranking findings

By consequence, not by how interesting the fact was:

1. **Trip-breaking**: a missed flight, a stranding, the last train gone.
2. **Anchor-breaking**: a locked, paid or unrepeatable commitment is missed.
3. **Want-losing**: something on the list becomes unreachable.
4. **Rush**: it works, with no slack left.
5. **Noted**: fine, worth knowing.

Lead with the worst. A report that opens with a shrine's gift-shop hours has buried the missed connection.

## The booking clock

The findings above can mostly be improvised around on the day. A booking window that closed cannot. So the checklist is ordered by **when its window opens**, counted from today, not grouped by category.

Each item carries: what it is, when the window opens, how long booking takes, what happens if it is missed, and whether the miss is recoverable.

**Convert every window into the traveller's home timezone.** "Opens one month prior at 10:00 local" is the previous evening at home, and a checklist that quietly leaves it in destination time will be read as a morning task and missed by half a day.

Watch for: timed-entry attractions, restaurants with reservation windows, sleeper trains and other single-departure services, seat reservations that open on a fixed date, rail passes that must be bought before arrival, events whose dates are not published yet, and anything requiring a printed or posted document.

Write the checklist to `~/.claude/vacation/trips/<slug>/checklist.md` and print the path. It gets used across weeks, so it lives outside the conversation.

## Research economy

Verification is web-heavy and mostly parallel. Fan out by fact class rather than by day, so one agent holds all the venue lookups and another all the transit; the concurrency ceiling in `CLAUDE.md` applies. Read `references/research-playbook.md` for which class of fact is settled by which source.

**Only verify what binds.** A cafe's hours in the middle of an open afternoon costs a lookup and changes nothing. Spend the searches on: anything in front of a hard-timed anchor, anything on a checkout or travel morning, the last item of any day, and anything the plan already flags as tight.

## Output

1. Findings, ranked, each naming the slot it affects and what it costs.
2. The corrected numbers written back into the trip file's transit table, with the date checked.
3. The checklist, path printed.
4. One sentence on whether the plan survives as written.

Offer to hand the breaking findings to `vacation:planner` for a re-solve. Do not re-solve here.

## Gotchas

- **Closing time and last admission are different numbers**, often by half an hour or more, and plans die on the second one. The same gap exists between a site's gates and its shop or ticket office.
- **A verified fact has a date on it.** Hours pages go stale and search results cache old seasons. Record what you checked and when, so the next pass can tell a fresh fact from an inherited one.
- **Station to station is not door to door.** A 2h27 train is comfortably a 3h30 leg once the walk at both ends, the interchange and a luggage-slowed checkout are counted.
- **Frequency beats duration for risk.** Ask how often the service runs before worrying about how long it takes.
- **A holiday changes more than hours.** It fills trains, closes offices that sell the thing, and empties reservation availability weeks earlier than usual. Check the actual dates against the destination's calendar.
- **Sunset is a constraint on outdoor items**, and in late autumn it arrives far earlier than travellers from other latitudes expect. Anything scenic after it is a different experience from the one that was planned.
- **The traveller's own facts are inputs, not gospel.** When someone says a venue closes on Tuesdays and the published hours say daily, both can be true of different parts of the same place. Report the conflict rather than picking a side.
- **Unverifiable is a legitimate result and reporting it is required.** The temptation is to keep the planner's estimate because it looks like a number. Name the gap and the fallback instead.
