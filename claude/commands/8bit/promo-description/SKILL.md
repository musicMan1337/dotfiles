---
name: 8bit:promo-description
model: sonnet
description: Write post-booking promo copy for 8 Bit Mammoth: show descriptions, venue event blurbs, social posts, press kit bios. Use when a booking is already confirmed and the user needs copy to publish (NOT for elevator pitches or cold outreach). Triggers on, promo description, show description, write the blurb, draft a post for the show, venue copy, event description, write a bio for the band, 8 bit mammoth post, promo for the gig.
---

# 8 Bit Mammoth: Promo Description

Generate post-booking promo copy. The user already has the gig; this skill produces the words to publish.

## Read first (every invocation)

These three references define the band's facts, voice, and configurations. Read them at the start of every run, in this order:

1. `../references/voice-tone.md`: non-negotiable style guardrails. This is the most important file.
2. `../references/configurations.md`: group-size framing.
3. `../references/repertoire.md`: what pieces exist, how to pick touchstones.
4. `../references/band-overview.md`: facts and source of truth.

If any reference is missing, stop and tell the user before writing copy.

## What this skill is for, and not for

**For:** producing copy after a booking is confirmed. Show descriptions for venue event pages, Facebook/Instagram event bodies, short social captions, Story text, longer "about the band" bios for press kits or websites, and paste-ready blurbs the venue will post from their own account.

**Not for:** elevator pitches, cold outreach to venues that haven't booked us, EPK selling, press releases announcing the band. A companion skill will handle pitching. If the user's request is clearly pitch-shaped (selling the band to a stranger, asking for a booking), say so and offer to switch.

## Intake: ask before writing

Before drafting, gather what you need. Use AskUserQuestion when there are real choices; ask plainly when one or two facts are missing. Do not invent specifics.

Required facts:

- **Format / where it lands.** Venue event page paragraph? Facebook event body? Instagram caption? Press kit "about" section? The format determines length and register. If unclear, ask.
- **Approximate length.** Short (≤40 words, social caption), medium (80–150 words, event body), long (200–300+ words, bio). Offer these as defaults if the format hints at one.
- **Group size for this booking.** Small (5–8), mid (10), large (12+). Determines what's in scope to mention.
- **Vocalist?** Yes/no.
- **Anything special about the show.** Themed night? Album release? Opening for someone? If "no, just a normal set," fine, note it and move on.

**Do not ask whether to name specific songs, games, or IPs.** Default copy does not name them. The user will say "include X" if they want it named; until then, describe the band and source material in general terms only ("video game music," "soundtracks," "themes," "grooves"). This is a hard rule, not a preference. See `voice-tone.md` for the reasoning.

Do not ask for hashtags or @-mentions unless the user mentions wanting them. Default output is prose only.

## How to write the copy

Draw the voice from `voice-tone.md`; that file is the spine. Then:

- **Open with the band, not with throat-clearing.** First sentence names what we are and what we do, in concrete terms. "8 Bit Mammoth is a [size]-piece ensemble arranging…" beats "Get ready for an unforgettable night…"
- **No titles by default.** Do not name songs, games, anime, or franchises. Describe the band's craft on generic source material: "themes get pulled into ballads," "grooves get opened up for soloing." The `repertoire.md` file exists only for cases where the user explicitly asks for a piece to be named. Otherwise, do not consult it.
- **Match the configuration.** Don't reference large-production material framing if the booking is a 6-piece. Don't talk about combo intimacy if it's a 14-piece headliner.
- **A light, friendly close is fine.** "Catch us at The Nash," "come hang," "we're playing Saturday at X": these are welcome when they fit. Avoid hard-sell registers ("you NEED to be there!", "tickets going fast!").
- **Length discipline.** Every sentence does work. If a line could be deleted without losing meaning or character, delete it. Short copy is usually the harder craft, so lean in.
- **First-person collective is the default voice.** "We're 8 Bit Mammoth," "we play," "we love": this is the register that's landed. Use third-person only when the format explicitly calls for it (long-form bios, press kits, anything a venue will post from their own account) or the user asks. A venue pasting "we're 8 Bit Mammoth" into their own feed reads as a mistake, so blurbs written for someone else to publish are always third person.
- **Nostalgia is fair game.** The shared-memory pull of game music is a real part of why people show up, so don't sanitize it out. "That sweet nostalgia beat," "the songs you grew up on," "soundtracks we grew up loving": all welcome when they fit.
- **Vibe over craft enumeration.** Once the copy has warmth and energy, do not stack a craft-detail clause on top ("the horns dig in and the solos run long"). The vibe carries the description. See `voice-tone.md` reference example for the target register.

## Output structure

By default, produce **2–3 variants** of the requested length. Variants should differ in approach (e.g., one leaning craft-forward, one leaning source-forward, one tighter and more atmospheric), not just rearranged sentences. Label them briefly so the user can pick.

After the variants, ask if they want any adjustments, and only then ask about hashtags or @-mention placeholders if the user signals they'll be posting to a platform where those apply.

## Gotchas

These are the recurring failure modes. Watch for them in your own drafts before returning.

- **Don't open with "Get ready for…" or any throat-clearing.** Open with the band.
- **Don't name songs, games, or IPs at all unless the user explicitly requested specific titles for this draft.** Not one, not two. None. The cap is zero by default. If the user asks for touchstones, then use `repertoire.md` and the one-or-two-max rule applies.
- **Don't be snobby.** No "rather than as novelty," no "the kind of audience that," no "music that happens to come from games." Don't position the band against other approaches, don't flatter the audience's taste, don't apologize for the source.
- **Don't use stiff "writerly" upgrades.** "Band" beats "ensemble." "Playing" beats "reading." "What we play" beats "the book." If the plainer word fits, take it.
- **Don't name members.** Collective only. If the user says "feature our soloist," ask for the name and use it, but don't invent rosters.
- **Don't claim things the references don't claim.** No invented founding years, awards, press quotes, member counts beyond the configurations file, or venues we haven't actually played. If the user supplies them, fine. Otherwise leave them out.
- **Don't match repertoire to a size that doesn't carry it.** Cowboy Bebop / Seatbelts material is large-group only. Big-production anime: large-group only. Watch this.
- **If the user explicitly asks for titles, italicize source names and use title case for piece names.** *Cowboy Bebop*, *The Legend of Zelda*, Tank!, NBA Jam.
- **Format hashtags and @-mentions only when the user asks for the platform.** Default prose-only.

**Note on the "cringe ban" that used to live here:** an earlier version of this skill banned hype words, exclamation marks, casual catchphrases, and self-aware nerd framing wholesale. That ban over-corrected: it produced copy that read sanitized, stiff, and snobby. Those moves are *not* banned anymore. Enthusiasm and warmth are encouraged. The voice file is the source of truth for what to lean into.

## When the user asks for hashtags / @-mentions

Only when they say where they're posting:

- **Hashtags:** 4–8, mix of genre (#FunkJazz, #JazzFusion), source (#VideoGameMusic, #CowboyBebop, #AnimeMusic), and one or two specific franchises if relevant to the show. Avoid overstuffed strings of 20+. No all-caps gimmicks.
- **@-mention placeholders:** insert `[@venue]` and `[@anyone-else]` for the user to fill; do not invent venue handles.

## Growing this skill

When the user corrects a draft, treat the correction as voice intelligence. If the same correction comes back twice (e.g., "stop using that word," "I never want to see that phrase again"), add it to the banned list in `../references/voice-tone.md` so future runs internalize it. The references are where lessons live; the SKILL is the workflow.
