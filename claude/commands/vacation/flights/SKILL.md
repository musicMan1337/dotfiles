---
name: vacation:flights
description: Find the best round-trip flights for given dates, ranked so the price-vs-convenience tradeoff is explicit (nonstop preferred, stops only when the savings are compelling). Searches Google Flights and ITA Matrix in the Claude Chrome profile, checks point-of-sale pricing on international routes, verifies the winner on the airline's own site, and logs prices for baselines. Triggers on, flights, flight search, look up flights, round trip to, find me a flight, cheap flights to, flight prices, vacation flights, /vacation:flights.
---

# vacation:flights

Find round-trip options for a route and dates. The deliverable is a ranked table plus one recommendation, with the winning fare confirmed live on the operating airline's own site.

Read `references/pricing-mechanics.md` before the first search of a session, and any time the plan drifts toward incognito windows, cookie clearing, or a VPN: it explains what actually moves fares and which counter-moves are real.

## Inputs

Ask only for what the request left out:

- Origin and destination (airport or city; note if nearby airports are acceptable)
- Dates and flexibility (exact, ±N days, "that week")
- Travelers and cabin (default 1 adult, economy)
- Hard constraints: max stops, carriers to avoid or prefer, red-eye tolerance, checked/carry-on bags

Bags decide whether a basic-economy fare is even comparable, so always get that one.

## Search

All browsing happens in the Claude Chrome profile (global rule). That profile is logged out and clean, which is all the anti-tracking hygiene the evidence supports.

1. **Google Flights, date grid first.** Enter the route, open the date grid / price calendar, and find the cheap date pairs inside the flex window. Dates move price more than anything else the user controls.
2. **Drill into the best 1-3 date pairs.** Capture each candidate: price, total duration, stops, layover airports and lengths, carrier, fare class.
3. **ITA Matrix when routing gets exotic.** Multi-city, forcing a connection point, alliance filters, or thin Google Flights results for a route that should have more.
4. **Point-of-sale check, international routes only.** Re-price the leading itinerary in the destination country's site edition or currency (currency switcher on the airline site or in Google Flights settings; no VPN needed for comparison). Worth the minute when the operating carrier is foreign.
5. **Holdout-carrier sweep.** Some carriers withhold fares from metasearch. If a budget carrier serves the route and Google Flights doesn't show it, price the carrier's site directly before concluding.

## Rank and recommend

Nonstop wins by default. A connection has to buy its inconvenience: flag a connecting option only when it saves roughly $50+ per hour of added travel time, and discount it further for overnight layovers, tight connections (under 45 min domestic, 90 min international), or an unrequested red-eye.

Output a table: rank, price, carrier, depart/return times, total duration, stops (layover airport + length), booking source. Then one recommendation with the reasoning in a sentence or two.

Prefer booking direct with the airline when its price is within a few dollars of an OTA: the fare re-prices at checkout anyway, and direct tickets are easier to change or cancel.

## Verify before reporting

The search is done when the winning itinerary is opened on the operating airline's own site and the price holds in that session. A fare that survives this check is real. A fare that jumps was a stale cache: fall back to the runner-up or re-run the date pair.

## Price log

Append each run's best finding to `~/.claude/vacation/price-log.md` (create the file and directory on first run):

```
| logged | route | travel dates | best price | carrier | stops | notes |
```

Read the log at the start of a run when the route has history: it turns "is $412 good for this route?" into a comparison. The log lives outside the dotfiles repo because the repo is public and travel plans are not.

## Gotchas

- **Skip the incognito/cookie ritual.** Search-history price hikes are a debunked myth (DOT 2015, Consumer Reports 2020, NBER); the ritual costs time and changes nothing. A price that rose between searches means a fare bucket sold out, and waiting rarely brings it back.
- **OTA prices are cached quotes, not offers.** Kayak/Expedia/Priceline fares re-price at checkout. Treat metasearch numbers as leads; the airline-site verify step is where a number becomes real.
- **Compare like for like on fare class.** A cheaper basic-economy fare with no carry-on can lose to a standard fare once bags are added. Price the fare the user will actually buy, bags included.
- **POS arbitrage has a failure mode.** Booking in a foreign edition with a mismatched billing country can trip fraud detection and void the ticket. Comparing across editions is free; actually booking in a foreign POS is a call the user makes knowingly (see the reference).
