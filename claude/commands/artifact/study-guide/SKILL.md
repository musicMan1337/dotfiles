---
name: artifact:study-guide
description: Turn a manual, textbook, spec, or course packet into a single self-contained HTML study artifact, a page-indexed reference plus a randomized multiple-choice practice test that scores, cites the page for every answer, and resumes where you left off. Use for open-book exam prep, certification study, onboarding a dense document, or any "help me study this" request. Triggers on, study guide, help me study this, summarize this manual for a test, exam prep, practice test, quiz me on this document, open book test, cram sheet, flashcards for this pdf, cert study guide, /artifact:study-guide.
model: opus # every claim and quiz answer is page-cited from a source doc; a wrong answer in a study aid teaches the wrong thing, so this is correctness-critical synthesis (TIERS: DEEP).
---

# /artifact:study-guide

Builds ONE self-contained HTML file with two views:

1. **Reference** in source order. A block per page worth flipping to, tagged with that page number, plus a cram sheet of hard numbers, wide lookup tables, and a conflicts section. Live search filters page blocks, table rows, and number tiles at once.
2. **Practice test.** Randomized multiple choice, one question per screen, scored against the real passing cut, with per-question review that expands to show the correct answer, the page, and why. State lives in `localStorage`, so leaving the test or reloading resumes it.

The reader's job is to answer a question fast with the source open next to them. Optimize for "read the question, find the row, flip once", not for reading the guide top to bottom.

## Load first

- The `artifact-design` skill (its augment hook pairs the house design system automatically). The engine asset below assumes mammoth `--mm-*` tokens exist.
- The engine: `~/.claude/commands/artifact/study-guide/assets/engine.html`. Copy it as the starting file; it carries the verified CSS, search, theme toggle, and the whole test engine with a 2-item sample bank. Fill it in rather than re-deriving any of it.

## Fidelity rules

These are what make the artifact trustworthy enough to study from.

- **Establish the page-number mapping before citing anything.** Printed page numbers and PDF page numbers often differ by a front-matter offset. Check the mapping at three widely separated pages, then state it in the masthead lede ("printed page numbers match PDF pages 1:1", or "printed page = PDF page minus 4"). Cite the number the reader will see in their copy. Getting this wrong makes every citation useless.
- **Cite a page for every fact and every quiz item.** No claim in either view exists without a page the reader can turn to. If you cannot find the page, the claim does not go in.
- **Never smooth the source's language.** Preserve "may" versus "shall", exact dollar amounts, exact day counts, and the exact list length ("seven qualifications"). An exam tests the difference between may and shall; a paraphrase that loses it is worse than no summary.
- **Never invent, extrapolate, or helpfully complete.** If the source is silent, the guide is silent. If the source contradicts itself, that goes in the conflicts section rather than getting resolved silently.
- **Carry the source's own numbers into the cram sheet verbatim**, including ranges and penalties. Numbers are the most-tested and most-mistyped content in the artifact; re-read them against the source text once the draft exists.

## Build order

Adapt freely, but the sequence matters where noted.

1. **Extract text with page boundaries.** For a PDF: `pdftotext -layout in.pdf out.txt`, then split on form feed (`\f`), which yields one chunk per PDF page. Squeeze runs of whitespace and prefix each chunk with a `<<<PAGE n>>>` marker before reading, so page attribution survives into your notes. Sidebars in two-column layouts interleave with body text; read the whole page before deciding what a sentence belongs to.
2. **Read the whole source.** Not a sample. A study guide with a gap in the middle is a trap. For long sources, read in sequential chunks rather than skipping to what looks important; the tested details hide in sidebars and penalty boxes.
3. **Build the page map first**, one line per page: what is on it and whether it is high yield. That map becomes the section skeleton.
4. **Draft the reference view.** One `.pg` block per page that earns a flip. Lead each bullet with the testable claim, then the qualifier. Bold the operative number or the may/shall word. Use `ol.steps` only when the source is genuinely a sequence.
5. **Draft the question bank** (rules below).
6. **Assemble** from `assets/engine.html`, following the two STEP comments at the top of its `<style>`.
7. **Exercise it in a browser before saying it works** (house rule: nothing is done until it is exercised). Drive it: start a run, answer, score, expand a result row, hit Restart test, reload and confirm the run resumed. Playwright MCP blocks `file:` URLs, so serve the directory (`python3 -m http.server <port>`) and navigate to `http://127.0.0.1:<port>/<file>.html`. Check the console for errors, and confirm no glyph renders as mojibake.
8. **Deliver** per the house artifact flow: write to `~/dotfiles/artifacts/<slug>.html`, print the absolute path and nothing else, then offer numbered options (keep local / publish / change something). Publishing and the Obsidian manifest row are `augment:artifact-design`'s job; do not duplicate that here.

Also offer a plain-Markdown companion when the user wants something greppable or printable; the artifact and the `.md` can share the same outline.

## Question bank rules

The bank is the part most likely to be quietly wrong, so treat each item as a factual claim with a citation.

- Shape per item: `{ q, o: [4 options], a: 0, p: "p.N", w: "why" }`. **Author the correct option first with `a: 0`**; the engine shuffles question order and option order at runtime, so authored position never leaks. Do not pre-scramble by hand.
- The stem must be answerable without seeing the options, and must not contain the answer.
- Distractors are plausible neighbors drawn from real adjacent facts in the source (the other deadline, the other dollar amount, the rule that applies to the sibling act). Absurd options make a question free.
- Exactly one option is defensibly correct. If two could be argued, rewrite the stem.
- `w` is one or two sentences that teach the distinction, not a restatement of the option.
- Aim for **at least twice your longest run length** so consecutive runs differ, and weight the bank toward what the source itself flags as tested: numbers, deadlines, penalties, and the near-identical pairs.
- Cover the whole source, including the statute or appendix material, and include a few "which is NOT" items since real exams use them.
- No duplicate stems. Re-check numeric answers against the source text after drafting; a transposed digit in an answer key is the worst possible defect here.

## What the engine already does

Do not rebuild these. The ids in the test markup are load-bearing (the script queries them by id); edit copy, not ids.

- Question and option shuffling, one-question-per-screen paging, Back/Next, progress bar, answered count, elapsed clock that pauses when you leave the test view, and keys 1-4 plus arrows.
- Scoring with a pass/fail verdict, blanks counted as missed, then a result row per question with a Correct / Missed / Skipped chip, the page chip, and an expandable detail showing every option, a check on the correct one, a cross on a wrong pick, and the explanation. Plus "Expand every miss".
- `localStorage` persistence under one key, restore on load, a Restart test button that clears it, and a graceful session-only fallback when storage is blocked.
- Search over every `[data-unit]` element (page blocks, table rows, number tiles), with match count, an escape-to-clear, an empty state, and auto-hiding of sections and tables left empty by the filter.
- Theme toggle wired to the mammoth three-state theme tokens.

Set the passing cut, the run-length buttons (`data-len`), and the exam-shape copy on the start pane to match the real exam.

## Gotchas

1. **Declare the charset and keep the file ASCII-only.** The artifact content has no `<head>` of its own, so a local file opened over `file:` can decode as latin-1 and turn check marks into mojibake. Keep `<meta charset="utf-8">` as the first line, and express glyphs as JS escapes (`\u2713`) or CSS escapes (`\2315`) rather than literal characters. Verified failure, 2026-08.
2. **Panes are toggled with the `hidden` attribute**, which only works because no CSS sets `display` on those elements. If you give `#qPane`, `#rPane`, `#startPane`, `#progWrap`, or `#testview` a `display` rule, they stop hiding. Use classes for looks, `hidden` for state.
3. **Every color must be defined in all three theme states** (bare `:root`, `[data-theme='dark']`, and the `prefers-color-scheme: dark` guard). A token defined only inside a media or `[data-theme]` block renders one theme's text on the other theme's ground for anyone on the default "system" setting.
4. **The hard-offset shadow needs a per-theme color.** mammoth's `--mm-shadow-hard` uses ink-900, which disappears on a dark ground. That is why the engine expects `--fg-hard` / `--fg-hard-sm` in each theme block. Keep the shadow on the number tiles only; piling it on cards too loses the fingerprint.
5. **Restoring saved state must not clobber the phase.** Paint the start pane first, then apply the restored run and phase, then route on open. Doing it in the other order shows a resumable run but sends the user back to the length picker.
6. **The clock is elapsed-in-test, not wall time.** Accumulate into a base on every pause (leaving the view, scoring, unload) and restart from `Date.now()` on resume. Persist the accumulated value, never a start timestamp, or a run resumed tomorrow reports a 20-hour test.
7. **Do not let the source's own cross-references into the guide unchecked.** Manuals routinely point at the wrong page after a re-layout. Verify each internal pointer you repeat, and put the broken ones in the conflicts section; they are exactly the traps a reader loses time on.
8. **Numbered markers must encode real order.** Page numbers and a source's own numbered steps are real sequences. Do not number a set of unordered facts just for visual rhythm.

## Reference implementation

The Arizona Notary Public Reference Manual guide is the first instance of this shape: 66 source pages, a 90-item bank, at `~/dotfiles/artifacts/az-notary-manual-index.html` with a Markdown companion at `~/Downloads/AZ-Notary-Manual-Summary.md`. Both are local and gitignored, so they may not exist on another machine; `assets/engine.html` is the part that ships.
