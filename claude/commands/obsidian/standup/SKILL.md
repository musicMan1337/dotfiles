---
name: obsidian:standup
# haiku = cost pick (2026-07, see claude/TIERS.md): gather.mjs does the deterministic
# heavy lifting and a human approves before write. Promote a tier if grouping/
# weighting quality misses recur.
model: haiku
description: Generate standup notes from Claude Code sessions and write to Obsidian. Triggers on: standup, draft standup, what did I do today
---

# Standup Notes

Generate concise standup bullet points by scanning Claude Code session history, then write them to Obsidian.

## Input

**Request:** $ARGUMENTS

- No args or "today" → scan today's sessions
- "yesterday" → scan yesterday's sessions
- A date like "2026-03-18" or "monday" → scan that day
- "all day" / "the whole day" / "the entire day" / "full day" → pass `--start 0 --end 24` (no time filtering)
- The user may also specify a custom time range. Look for phrases like:
  - "I worked until 6" / "worked until 8pm" / "ended at 21" → override end hour
  - "started at 4am" / "I was up early, started at 4" → override start hour
  - "from 8 to 22" / "8am-10pm" → override both
- Parse these into integer hours (24h). Defaults remain 6am start, 5pm (17) end.

## Step 1 — Gather everything (one deterministic call)

Run the gather script. It resolves the date, reads the vault files directly from the filesystem (no fragile `obsidian read` calls), extracts session activity, and returns one JSON bundle:

```bash
node ~/.claude/commands/obsidian/_lib/gather.mjs --for standup [DATE] [--start HH] [--end HH]
```

- `DATE` is the resolved target token: `today` (default), `yesterday`, a weekday name (`monday`..`friday`), or `YYYY-MM-DD`. Map the user's request to one of these; the script owns the actual date math, so never compute or guess a date yourself.
- Pass `--start`/`--end` (24h integers) only if the user specified a custom time range. Defaults: 6am-5pm. For "all day" pass `--start 0 --end 24`.

The bundle contains:
- `date`, `weekday` — authoritative resolved date
- `sessions` — per-session prompts, tools, files edited/created, commits, branches (within the window)
- `reviews` — `{exists, content}` for `reviews/<date>.md` (PR notes)
- `followups.completedForDate` — `[{item, note}]` for follow-ups closed on the target date
- `standup` — `{exists, content, isFinalized, completedBlock}` for the existing standup file
- `wikilinkTargets` — `{investigations, decisions, reviews}` note slugs for Step 3b

### PR notes prerequisite

If `reviews.exists` is `false`, invoke the `/obsidian:pr-notes` skill (via the Skill tool) for `date`, then **re-run the gather call** so the bundle picks up the new PR notes. PR review work belongs in PR notes first so the standup can wikilink it. PR reviews are real work, give them their own bullet (e.g., "Reviewed PR #1234, feedback on error handling in auth flow").

### Completed follow-ups

`followups.completedForDate` lists follow-ups the user closed that day plus their outcome notes. Each becomes its own standup bullet (e.g., "Followed up with Chris on PHP PR, tests pass, merged").

### Existing Completed items are LOCKED (critical for incremental synthesis)

The briefing skill creates the standup earlier in the day; `/obsidian:standup-add` appends to its `## Completed` section throughout the day in the user's own voice.

**If `standup.completedBlock` is present, those items are frozen, they stay verbatim.** Do not rewrite, condense, re-word, or reorganize them. Your job in Step 3 is purely additive: find work in `sessions` that is NOT already represented in `completedBlock` and propose ONLY those as new items.

## Step 3 — Synthesize into standup bullets

From the extracted session data, PR notes, **and** any completed follow-ups, write **detailed, outcome-focused** bullet points. The standup is a comprehensive record of what was actually accomplished — it should demonstrate the full scope of work done, not just high-level summaries. Think about what a team lead cares about in standup — not "edited 5 files" but "fixed the auth middleware bug blocking OAuth flow."

**Incremental synthesis rule (when existing `## Completed` section present):**
- Existing Completed items are frozen — do NOT rewrite them
- Only synthesize ADDITIONAL items that aren't already captured
- Cross-check each session's work against existing items before proposing a new bullet
- If a session's work is already represented (even partially), skip it rather than duplicating or "enhancing"
- When presenting the draft for approval, clearly label which items are existing (kept verbatim) vs new (proposed additions)

**Verbosity goal:** The standup is the source of truth for the day's work. Be thorough — include specific files, components, case numbers, technical details, and decisions made. Other skills (like the briefing) will condense this into shorter summaries. The standup itself should be verbose enough that someone reading it months later understands exactly what was done and why.

**How to synthesize:**
- Group related activity across sessions by project/feature, not by session
- Derive the **what** from user prompts (intent) + files touched + commits (outcomes)
- Use commit messages as the strongest signal — they describe completed work
- Branch names often encode ticket/feature context (e.g., `Derek/334513-PROSyncing`)
- If a session has many edits but no commits, it's likely work-in-progress — note it as such
- Include specific details: file names changed, components affected, error counts fixed, tools/libraries involved
- Collapse only truly low-signal activity (pure file browsing with no outcome) — if reading/exploring led to a discovery or decision, include it
- Completed follow-ups should appear as their own bullet(s) using the completion notes
- PR reviews and authored PR activity should appear as bullets, with wikilinks to the PR notes file

**Format — numbered headers with sub-bullets:**
```
1. **Project/Feature** (branch-or-context)
   - Detailed outcome bullet — what specifically changed, why, and what it affects
   - Another bullet with specifics (file names, component names, case numbers)
   - Sub-tasks or secondary outcomes from the same effort
```

Aim for 3-6 numbered sections. **Weight the number of sub-bullets proportionally to time spent** — if 60% of the day was on one feature, that section should have ~60% of the total bullets. Don't give equal bullet counts to a 6-hour focus area and a 30-minute task. Use session duration, number of tool calls, and volume of file edits as proxies for time spent. Each section should have 2-5 sub-bullets capturing the specifics. Merge only truly trivial items. Don't include personal/non-work sessions.

## Step 3b — Enrich bullets with wikilinks

Before writing, scan the approved bullets for any investigations, decisions, or PR reviews that have Obsidian notes. If a bullet references something with a matching note, add an inline wikilink.

Use `wikilinkTargets` from the gather bundle (already fetched in Step 1, no extra calls) as the list of real note slugs to match against.

**How to add links:**
- If a bullet mentions research that produced an investigation note: `[[investigations/YYYY-MM-DD-slug|React-First Migration]]`
- If a bullet references a decision: `[[decisions/YYYY-MM-DD-slug|decision]]`
- PR review/authored bullets: `[[reviews/YYYY-MM-DD]]`

Only add wikilinks where a real note exists — don't fabricate paths. Keep the bullet readable; the link should wrap a natural phrase, not be tacked on awkwardly.

## Step 4 — Write to Obsidian

Use the Obsidian CLI to write a per-day file. The CLI requires `source ~/.zprofile &&` before each `obsidian` command.

**File path:** `standup/YYYY-MM-DD.md` (e.g., `standup/2026-03-18.md`)

The gather bundle's `standup.exists`/`content` already tells you whether a file is there, no extra read needed. If it exists and has content beyond the locked Completed items, ask the user whether to overwrite or skip.

**CRITICAL: You MUST show the user the draft and wait for their approval before writing to Obsidian.** Do not write the file until the user confirms or requests changes. This is a hard gate — never skip it.

```bash
source ~/.zprofile && obsidian create path="standup/YYYY-MM-DD.md" content="..." overwrite
```

**Output format — flat list only.** A completed standup is a numbered list of what was done. No section headings (`## Yesterday`, `## Today`, `## Completed`), no subsections. The briefing skill may have created the file with those sections earlier in the day — when completing the standup, replace the entire file with just the flat numbered list. The filename is the date; no heading needed.

**Flattening rule:** When flattening the existing standup file into the final list, the source of truth is the `## Completed` section (locked, verbatim) + any approved new additions from Step 3. Drop all briefing context sections — `## Today`, `## Open Follow-ups`, `## Active Investigations`, `## PRs Awaiting Your Review`, `## Your Open PRs` (and any legacy `## Yesterday`). These are reference context only. For `## Today`, checked items (✓) are usually already reflected in `## Completed` via standup-add, so don't duplicate.

## Step 5 — Clean up consumed follow-ups

After successfully writing the standup file, remove the completed follow-up entries that were incorporated. For each follow-up that was completed on the target date and included in the standup:

1. Remove the entire entry — both the `- [x]` line and its `  - **Completed ...**` sub-bullet — from `followups.md`.
2. Rewrite the file:
```bash
source ~/.zprofile && obsidian create path="followups.md" content="..." overwrite
```

This prevents completed follow-ups from accumulating in the file once they've been captured in standup notes. Only remove entries that were actually included in the standup — leave other completed or pending items untouched.

## Gotchas

- **Source zprofile:** The Obsidian CLI is not on PATH by default. Always prefix commands with `source ~/.zprofile &&`.
- **Prompts can be noisy:** User prompts often contain tool results, command outputs, and system messages. Look past the noise to find the actual intent.
- **Don't list tool usage as work:** "Used Read 47 times" is not a standup bullet. Synthesize what the reading accomplished.
- **Work hours default to 6am-5pm.** If the user overrides the window, respect their override. Otherwise don't second-guess the defaults — anything outside is personal time.
- **Multiple sessions, same project:** The user often has several sessions in one repo throughout the day. Merge these into unified bullets per feature, not per session.
- **Skill/command invocations in prompts:** Prompts starting with `<command-name>` or `<command-message>` are slash command invocations — use the command name and args to understand intent, ignore the XML noise.
- **PR notes are prerequisite.** Always ensure PR notes exist before synthesizing the standup — this avoids duplicate work and ensures wikilinks are valid.
- **Existing Completed items are locked.** If the standup file already has a `## Completed` section (from `standup-add` throughout the day), those items stay verbatim. Synthesis is purely additive — scan sessions for gaps, propose new items only. Never rewrite or condense what the user already captured.
