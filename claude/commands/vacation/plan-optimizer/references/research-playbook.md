# Research playbook

Which class of fact is settled by which source, and how to record the answer. Loaded when a verification pass starts.

## Source precedence

For any fact, work down until one answers, and record which one did:

1. **The operator's own site.** The venue, the railway, the airline. Slowest to find, only source that is authoritative, and the only one worth citing for an hours change.
2. **The operator's current-season notice.** Many sites publish winter or off-season hours on a separate page or a banner that aggregators never scrape.
3. **A national or municipal tourism body.** Good for holidays, seasonal closures and festival dates.
4. **Aggregators and map listings.** Fast, frequently stale, and the usual origin of a wrong closing time. Fine for locating a place, weak for its hours.
5. **A recent traveller report.** Last resort, and it downgrades the verdict to unverifiable with a note rather than confirming anything.

`WebFetch` fails on script-rendered pages and bot-blocked operators, which is most rail and venue sites. Firecrawl (`/firecrawl:firecrawl-cli`) returns clean markdown through both and is the right default for this work. Exa has limited credits; spend it on a named source that resists everything else.

## Fact classes

**Venue hours.** Operator site first. Capture four numbers, not one: opening, closing, **last admission**, and the closing day. Capture the shop or ticket office separately when the plan depends on buying something, since it usually shuts earlier than the site.

**Rail timings.** A journey planner for the actual date and time, because seasonal timetables and weekend patterns differ. Capture departure, arrival, frequency, and the interchange time at any station where you change. For anything ending after 21:00, capture last service on the return leg.

**Road and bus.** Rural and island buses are the weakest link in most plans: low frequency, seasonal timetables, and often no English publication. When no timetable is findable, mark it unverifiable, record the best estimate, and name the fallback (taxi, an earlier departure, a different day).

**Walking legs.** A map estimate plus a margin. Station exits are far from platforms in large stations, and a wrong exit costs as much as the walk. For a station you will pass through with luggage, assume the slow version.

**Holidays and seasonal closures.** The destination's official calendar for the actual dates. Note that a holiday falling on a Monday commonly moves a venue's usual Monday closure to the Tuesday.

**Sunset.** A single lookup per destination gives close enough for the whole trip. It binds any outdoor or scenic item scheduled late.

**Reservation and ticket windows.** The operator's booking page, not a guide. Capture the exact opening moment including the timezone, whether it is a fixed calendar date or a rolling window, and whether anything must be collected in person or posted.

## Door-to-door model

A published journey time is the middle of the leg, never the whole of it. Build every leg as:

```
leave the room               5 to 10 min, more on a checkout morning
reach the platform           10 to 15 min at a large station, more with tickets to buy
the published journey        the number the planner used
each interchange             the real published minimum, plus half again with luggage
station exit to the door     the map walk, plus margin for finding the right exit
```

Report the total and the published figure side by side so the size of the gap is visible. That gap, not the journey, is what turns a comfortable morning into a missed departure.

## Recording a verdict

Write into the trip file so the next solve starts from real numbers:

```
| leg or venue | plan said | actual | verdict | source | checked |
| Kyoto to Shin-Kobe | 0:50 | 0:32 + 12 transfer | corrected | JR West timetable | 2026-09-01 |
| Awaji bus, Sannomiya | 1:00 | no timetable found | unverifiable | fallback: taxi, 1h15 | 2026-09-01 |
```

The `checked` column is what makes a later pass able to tell a fresh fact from an inherited one. Without it every number looks equally trustworthy, which is how a stale hours page survives three revisions.
