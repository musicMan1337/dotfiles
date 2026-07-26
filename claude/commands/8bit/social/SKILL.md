---
name: 8bit:social
model: sonnet
description: Plan 8 Bit Mammoth's Instagram and Facebook presence. Posting cadence, the promo arc around a booked show, turning gig footage into posts, content mix, engagement rules, and account audits. Strategy and planning only; hands actual copy off to 8bit:promo-description. Triggers on, social strategy, social plan, what should we post, posting schedule, content calendar, promo plan for the show, instagram plan, facebook event, reels plan, how often should we post, our instagram is dead, social audit, clip from the gig, what do we do with the gig footage.
---

# 8 Bit Mammoth: Social Strategy

Plan what goes out and when. This skill decides the *shape* of the presence; `8bit:promo-description` writes the words.

## Read first (every invocation)

1. `../references/voice-tone.md`: the spine. Every rule here defers to it.
2. `../references/band-overview.md`: facts, source of truth.
3. `../references/configurations.md`: only when the plan is show-specific.

`repertoire.md` is off the table unless the user asks for titles, or a clip's tune needs naming (see "Titles" below).

## What this is for, and not for

**For:** posting cadence, content mix, the arc of posts around a booked show, deciding what to do with gig footage, engagement habits, auditing an account that has gone quiet.

**Not for:** writing captions, event bodies, or bios. When the plan calls for actual copy, say which post needs it and offer to hand off to `8bit:promo-description` with the format and length already decided. Do not draft the copy inline; the voice rules live in that skill and duplicating them here guarantees drift.

## The two platforms

Only Instagram and Facebook are in scope. Do not propose TikTok, YouTube, X, or Reddit unless the user brings them up.

- **Instagram** is the reach surface. Reels are how anyone who does not already follow the band finds it. Stories are for show-week presence and are the cheapest thing to post. The grid is the thing a venue booker looks at before replying to an email, so it should not be six months stale.
- **Facebook** is the RSVP surface. The event page is the actual conversion mechanism for a local show, it surfaces in local event search, and the venue can co-host it so the post reaches their following too. The audience skews older than Instagram's, which for this band is a feature, not a problem.

Cross-posting the identical asset to both is fine and expected. Do not build separate content lines for them.

## The show promo arc

The core deliverable. Given a booked show, produce this as a dated schedule the user can work from. Check the runway before writing the plan; under two weeks the plan changes shape, it does not just compress.

### Full runway (two weeks or more)

| When | Platform | What |
|---|---|---|
| 2–3 weeks out | Facebook | Event page live, venue co-hosting, body filled |
| 2–3 weeks out | Instagram | Announce post (grid), venue tagged, date in the image not just the caption |
| ~1 week out | Instagram | Reel built from past-show footage, date in the caption |
| 2–3 days out | Both | Story sequence and a Facebook event reminder; ask who is coming |
| Day of | Instagram | Morning Story, then load-in or soundcheck Story, then doors time |
| Within 48h after | Both | Thank the room, post one clip from the night |

Two things make this work. First, the date belongs *in the image*, because a screenshot of a post travels further than the caption does. Second, the post-show clip is not a victory lap, it is the promo asset for the next show. Every gig should end with footage in hand.

### Short runway (under two weeks)

There is not enough time for an announce to compound, and most of the room is already coming or not. Do not hand over a thinned-out version of the table and call it a plan. Lead with the capture decision instead, because that is the highest-value thing still open at this range.

1. **Capture first.** Who is shooting, where the tripod goes, what the audio source is. See "Gig footage." Settle this before discussing posts.
2. **Everything promotional lands at once, today:** event page, announce post, Story reshare of the announce.
3. **Midweek:** one Story with a who-is-coming prompt, one reminder in the event discussion.
4. **Day before:** Story, plus a rehearsal snippet if there is a rehearsal.
5. **Day of:** morning Story, soundcheck Story, doors time.
6. **Within 48h after:** thank the room, post the clip.
7. **Skip the Reel** unless one is already cut and ready. A rushed Reel is worse than none, and it competes with the post-show clip for attention.

### Who owns the event page

At an established room the venue usually already has the show listed. A second event splits the RSVPs and reads as amateur, so check before creating anything.

- **Venue already has an event:** ask to be added as co-host, then share it from the band page. Do not create a parallel one.
- **Venue has no event:** create it and request the venue as co-host.
- **Venue keeps a website calendar but does not use Facebook events:** create the event, link their calendar page in the body.

Never point the audience at two places to RSVP.

## Between shows

When nothing is booked, the account still needs a pulse, and the mix shifts.

| Type | Share | What it looks like |
|---|---|---|
| Live clip | ~40% | A minute of a tune from a past show. The engine of the whole account. |
| Show announce and reminders | ~25% | Whatever is booked. |
| Behind the band | ~20% | Rehearsal, charts on the stand, horns warming up, load-in, the van. |
| Nostalgia hook | ~15% | The source-material conversation. "What soundtrack owns your childhood." |

Note this deliberately does not cap promotional content at the usual 10%. People follow a band specifically to learn when it plays; show announcements are the service, not the ad. The failure mode to actually watch for is announce posts with *nothing between them*, which reads as an account that only shows up to ask for something.

**Cadence floor:** one feed post a week, plus Stories on show weeks. Two to three a week when a show is coming up. Ignore generic advice that an account below three posts a week should be abandoned; that is written for brands with staff. A sparse but live band account is fine. A six-month gap is not.

## Gig footage

One recorded show should yield several weeks of posts. Plan the capture, not just the edit.

- **Shoot vertical.** A horizontal audience video crops into a Reel badly, and reframing an eight-piece horn line into 9:16 loses the horns.
- **Get two angles:** one locked-off wide on a tripod for the whole set, one phone roaming for close work on the horn section and soloists. Cutting between them is what makes a clip look intentional.
- **Phone mics clip at this band's volume.** A horn section at gig level distorts built-in mics, and distorted audio is the single fastest way to make a good performance unpostable. Get a board feed, or a small recorder placed off-axis, and sync it in the edit. This is worth more than any camera upgrade.
- **Best clip length is a hook, not a chorus:** a solo entrance, a shout chorus, a section hit. Full tunes underperform and are the more likely thing to get flagged.

## Titles: the surface split

`voice-tone.md` bans naming songs, games, and IPs. That rule holds for all prose. It does **not** hold for discovery surfaces, because on a clip of a specific tune the name is what people search and withholding it costs reach while hiding nothing.

**Titles allowed:**
- On-screen text overlay on a Reel or Story
- The first line of a Reel caption, when the clip is that tune
- Hashtags

**Titles still banned:**
- Prose captions, event bodies, bios, anything `8bit:promo-description` produces
- Any post that is not a clip of that specific piece

Formatting note: Instagram does not render italics, so the italic-titles convention from `voice-tone.md` does not apply on-platform. Plain text, title case. Hashtags stay at 4–8 per the existing rule.

## Claims and takedowns

Game and anime music has active, aggressive rightsholders, and a posted cover can be muted, region-blocked, or pulled. Treat this as a live risk on every clip, not a settled question.

- Check the post 24–48 hours after it goes up, not just at upload. Claims often land late.
- A muted Reel is worse than no Reel; if audio gets stripped, take it down rather than leaving a silent video on the grid.
- Track which arrangements have drawn a claim before. That list is worth keeping in `band-overview.md` once it exists, so future clip picks avoid known-hot material.
- Do not assert what any specific rightsholder's policy is. Report what actually happened to the band's own posts.

## Engagement

- **Reply to every comment on an announce post.** That thread is the RSVP funnel; a reply is often what converts an "interested" into a person at the door.
- **DMs asking about booking or private events go to whoever handles booking, within 24 hours.** This is the highest-value message the account receives and the easiest one to lose.
- **Comment on the venue's posts and other local bands' posts.** Local scenes run on reciprocity and it is the cheapest reach available. Fifteen minutes a week beats any posting tweak.
- **Do not argue in the comments** about arrangements, tempos, or whether the original was better. Per `voice-tone.md`, the band does not position itself against other approaches; that holds in replies too.

## What to measure

- **Shares and saves**, over likes. A share is a person inviting a friend to the show.
- **Facebook "Going" and "Interested" against actual door count.** Learn the band's own ratio over a few shows; the absolute numbers mean nothing until you know how they translate.
- **Inbound asks:** "when are you playing next," booking DMs, venue inquiries.
- **Ignore follower count.** A local band with 400 engaged local followers outdraws one with 4,000 scattered ones.

## Audit mode

When the user says the account is dead or asks what is wrong, check in this order and report findings before proposing a plan.

1. When was the last post? Is there a booked show that went unannounced?
2. Does the bio say what the band is and where it plays, and does the link go somewhere current?
3. Is the top of the grid a clip, or is it all flyers? All-flyer grids do not convert strangers.
4. Of the last ten posts, how many are announcements with nothing between them?
5. Is there unanswered mail? Comments, DMs, event questions.
6. Is there gig footage sitting unused?

The fix is almost always footage plus cadence, not a new content idea.

## Gotchas

- **Do not write the copy here.** Name the post, hand off to `8bit:promo-description`.
- **Do not invent show details.** Dates, venues, ticket links, and set times come from the user.
- **Do not propose paid ads, influencer partnerships, or a posting tool subscription** unless asked. This is an organic, band-run account.
- **Do not name band members** in any plan output. Collective only, per `voice-tone.md`.
- **Do not plan around material a configuration cannot carry.** Large-production arrangements are large-group only; check `configurations.md` before building a clip plan around them.
- **Do not propose a cadence the band will not hold.** A plan that lapses in three weeks is worse than a smaller one that holds.

## Growing this skill

Numbers here are starting points, not findings. When the band's own data contradicts them, the data wins: adjust the mix, the cadence, and the arc timings in this file and note what drove the change. Voice corrections belong in `../references/voice-tone.md`, not here.

**Dated premise.** The content mix percentages, the weekly cadence floor, and the promo-arc timings are prescriptive scaffolding, not environment facts. They encode a reasonable default for a local gigging band absent any real performance data. (scaffold: patches missing band-specific engagement data; added 2026-07; retest once the band has a few shows of post-level analytics, or on any model upgrade, and replace with observed numbers or delete if the model plans a better arc unaided.) The platform roster, the title surface split, the claims risk, and the phone-mic clipping fact are environment facts and stay regardless.
