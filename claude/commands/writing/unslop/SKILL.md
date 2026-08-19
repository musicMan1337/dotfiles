---
name: writing:unslop
description: Cut AI tells out of shipped prose. Run on any generated document or artifact copy before it lands, README, PR body, spec, plan, ADR, case note, skill, report, artifact page. Triggers on, unslop, unslop this, cut the slop, deslop, does this read as AI, sounds like AI wrote it, clean up this writing, before we publish this doc, /writing:unslop.
---

# writing:unslop

Adapted from the `unslop` skill in [pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT, Lauren Tan).

## Scope

Generated **documents** and **artifact copy**: READMEs, PR bodies, specs, plans, ADRs, case notes, skills, reports, and every artifact page.

Out of scope, owned elsewhere:
- **Chat replies.** `~/.claude/CLAUDE.md` already governs those (concision first, fragments fine).
- **Code comments.** The comment policy in CLAUDE.md is stricter than anything here.
- **The em dash.** Banned outright by CLAUDE.md, everywhere, no exceptions. Nothing to decide.

## Process

1. Scan for the patterns below.
2. Rewrite. Preserve meaning, match the intended tone.
3. Add voice (next section).
4. Self-audit: "what makes this obviously AI generated?" Fix what is left.

Do this while drafting, not as a cleanup pass. A bad sentence rewritten still reads like a rewritten bad sentence.

## Voice

Pattern removal overshoots into clipped, sterile copy. The fix is rhythm and specificity, not personality. Voice is the smallest section here on purpose.

- Vary sentence length. A short sentence lands a point, a longer one carries a fact with its condition.
- Be specific. Not "this is concerning" but "the hook fails open, so a bad payload ships silently".
- Acknowledge a tradeoff where one exists. "Fast, but it drops the audit trail" beats "fast".
- **No first-person narrator.** A report describes the system, not the writer's experience of it. Drop "I", "my", and "we" from findings and assessments. A PR body or case note stating what changed can still say "I did X"; that is the authorship rule's territory, not this skill's.
- **No drama.** State a judgment about the thing, never a feeling about it. "The retry path is the bigger risk" works; "this bothers me more than the incident does" is theater. Same failure as rule 24, arriving through the front door.

## Patterns

**Content**
1. Puffery: "pivotal moment", "testament to", "evolving landscape", "setting the stage". Say what happened.
2. Superficial -ing clauses: "highlighting...", "ensuring...", "showcasing...", "reflecting...". Delete or replace with the real fact.
3. Promotional adjectives: "groundbreaking", "robust", "seamless", "powerful", "vibrant". Neutral description.
4. Vague attribution: "experts believe", "reports suggest". Name the source or cut it.
5. Formulaic tension: "despite challenges, X continues to thrive". Give the specific fact.

**Language**
6. AI vocabulary: additionally, crucial, delve, enhance, garner, interplay, intricate, landscape, pivotal, showcase, tapestry, testament, underscore. Plain words.
7. Fancy ways to say is: "serves as", "stands as", "boasts", "features". Say "is" or "has".
8. "Not just X, but Y." State the point.
9. Rule of three. Use the real number of items.
10. Synonym cycling. One name per thing, repeated. Switching synonyms makes the reader re-derive that they are the same thing.
11. False ranges: "from X to Y" where X and Y are not on one scale. List them.

**Style**
12. Colon as a mid-sentence connector. Fine before a list or example, not as a hinge.
13. Boldface on every proper noun.
14. Inline-header lists where the bold label restates the line ("**Performance:** performance improved"). A bold lead-in followed by genuinely new detail is fine.
15. Title Case Headings. Sentence case.
16. Decorative emoji in headings and bullets.

**Artifacts**
17. Chatbot phrases: "I hope this helps", "let me know if", "certainly", "found the smoking gun".
18. Sycophancy: "great question", "you're absolutely right".
19. Cutoff disclaimers: "while specific details are limited". Find the source or drop the claim.

**Filler**
20. "In order to" is "to". "Due to the fact that" is "because". "It is important to note that" is nothing.
21. Stacked hedging: "could potentially possibly" is "may".
22. Generic conclusions: "the future looks bright". State the next concrete step.

**Jargon**
23. Abstract metaphor nouns used where a concrete word exists: substrate, wedge, vector, locus, nexus, bedrock, modality, paradigm, flywheel, north star, evacuate (for moving code), gold-plating. Pick the plain word.
    House exception: **attack surface, harness, scaffold, spine, blast radius, ladder, rung** are load-bearing domain terms here, not metaphors. Keep them.

**Plain speech**
24. Say what it does, not how it feels. "the database stays close at hand" names a feeling; "`.toSQL()` returns the exact string sent to the server" names the mechanism. Ask what the sentence tells the reader to do or know, then write that. If it cannot be restated as a fact, instruction, or number, cut it.
25. If a sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.
26. Split dense sentences. One idea each. If the reader backtracks to parse it, it is two sentences.
27. Active voice. "Queries are validated" becomes "the compiler validates queries". Passive only when the actor genuinely does not matter.
28. Cut the adverb or use a stronger verb. "Runs quickly" is "is fast", or the measured number.
29. Prefer the plain word: use over utilize, use over leverage, help over facilitate, many over numerous, if over in the event that.

## Gotchas

- Both source suites are themselves em-dash heavy. Text lifted from any external skill or doc gets this pass before it lands in a file here.
- Rule 24 is the one with teeth. Most slop that survives a mechanical scan is a sentence that names a feeling.

(scaffold: patches the model's default register on generated prose, which is puffery plus feeling-words plus passive constructions rather than mechanisms, facts, and numbers; added 2026-08; retest when a fresh model's first-draft README needs no edits under rules 24, 25, and 27)
