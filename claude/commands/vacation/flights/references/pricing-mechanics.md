# Flight pricing mechanics

What moves airfares, what doesn't, and which counter-moves are real.

Dated premise: researched 2026-08. The tracking-myth findings span 2015-2020 and airline revenue-management incentives haven't changed, but re-verify if a regulator or credible study reports that personalized airfare pricing became real, or if the tool status below stops matching reality.

## The tracking myth

Airlines and metasearch sites do not raise a fare because a specific person searched it repeatedly.

- US DOT reviewed discriminatory-pricing complaints in 2015 and found no evidence of browsing-history-based pricing.
- Consumer Reports (2020) ran 372 simultaneous searches in clean vs lived-in browsers: 88% identical prices, and the differing 12% went in both directions.
- NBER/QJE studies on airline pricing reach the same conclusion; Google Flights, Kayak, and Expedia deny cookie-based repricing outright.

So incognito mode, cookie clearing, and IP rotation for the purpose of hiding search history are wasted effort. When a price jumps mid-search, a fare bucket sold out (see below); it was not a reaction to the searcher.

## What actually moves prices

1. **Fare buckets.** Each flight sells seats in tiered buckets (N seats at $X, then next tier). A bucket emptying is the "it went up while I decided" event. Bucket inventory occasionally reopens (cancellations, revenue-management resets), so a one-time jump is worth re-checking a day later, but waiting is not a strategy.
2. **Cache staleness.** OTAs and metasearch serve cached fares that re-price against the live GDS at checkout. Google Flights and ITA Matrix read fresher data than most OTAs; the airline's own site is ground truth.
3. **Point of sale (POS) and currency.** The same itinerary can price differently depending on the country/currency edition of the site selling it. This one is real and exploitable; details below.
4. **A/B tests and server skew.** Two simultaneous searches can differ for reasons that have nothing to do with the searcher. Explains most "my friend sees a cheaper price" reports.

## POS arbitrage (the real lever)

- **How to compare without a VPN:** most airline sites have a country/currency switcher in the header or footer; Google Flights has region/currency in settings. Switching editions changes the POS for the quote. IP address rarely locks the edition; the site setting usually wins.
- **When it pays:** mostly foreign carriers on international routes, priced in the carrier's home market or the destination country. Differences come from local demand, taxes, and currency spreads. Typical wins are a few percent; occasionally much more on long-haul.
- **VPN's actual role:** last resort for the minority of sites that force the edition from the IP and offer no switcher. Comparison via VPN is harmless.
- **The risk is at booking, not comparison.** Buying in a foreign POS with a mismatched billing country can trip the airline's fraud checks; carriers reserve the right to cancel such tickets, and some foreign editions require local payment methods. Surface the price difference and let the user decide whether to book it.

## Booking hygiene

- Book direct with the airline unless an OTA is meaningfully cheaper after the checkout re-price; direct bookings are easier to change, cancel, or claim compensation on.
- Not booking today? Turn on the Google Flights price-tracking alert for the route/dates instead of re-searching manually.
- The verify step in SKILL.md (open the fare on the airline's site, confirm it holds) is the final word on any number found via metasearch.

## Tool status (2026-08)

- **Google Flights:** primary tool. Date grid / price calendar, filters, price tracking alerts, fresh GDS data. Free, no login.
- **ITA Matrix (matrix.itasoftware.com):** the engine behind Google Flights, with advanced routing codes (force/exclude connections, alliance filters, date-range grids). Search only; it can't book. Use for exotic routing.
- **API dead ends, checked 2026-08:** Amadeus Self-Service keys stopped working 2026-07; Kiwi Tequila is invite-only; SerpAPI's Google Flights extraction is paid; Duffel targets booking businesses. Browser automation on Google Flights/ITA Matrix is the free, keyless path, which is why this skill drives Chrome instead of shipping API scripts.

Sources: [Time](https://time.com/4899508/flight-search-history-price/), [Going: incognito unnecessary](https://www.going.com/guides/you-dont-need-to-search-incognito-for-flights), [Mighty Travels cookie investigation](https://www.mightytravels.com/2024/12/do-browser-cookies-really-impact-flight-prices-a-data-driven-investigation/), [Cybernews VPN/POS](https://cybernews.com/how-to-use-vpn/how-to-get-cheap-flight-tickets/), [Thunderbit flight APIs 2026](https://thunderbit.com/blog/best-flight-api-with-free-tiers), [Upgraded Points ITA Matrix](https://upgradedpoints.com/travel/ita-matrix/)
