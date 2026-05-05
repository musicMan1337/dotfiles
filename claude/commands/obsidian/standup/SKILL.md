---
name: obsidian:standup
model: haiku
description: Generate standup notes from today's Claude Code sessions and write to Obsidian. Triggers on: standup, standup notes, draft standup, what did I do today, yesterday's standup, generate standup
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

## Step 1 — Run PR notes first (if needed)

Check if PR notes already exist for the target date:
```bash
source ~/.zprofile && obsidian read path="reviews/YYYY-MM-DD.md"
```

If no PR notes file exists for the target date, invoke the `/obsidian:pr-notes` skill (via the Skill tool) for that date before proceeding. PR review work should be captured in PR notes first so the standup can reference them with wikilinks.

If PR notes already exist, skip this step.

## Step 2 — Extract session data

Run the extraction script. Resolve the target date first, then execute:

```bash
node ~/.claude/commands/obsidian/standup/lib/extract-sessions.js [YYYY-MM-DD] [--start HH] [--end HH]
```

Pass `--start` and/or `--end` (24h integer) if the user specified a custom time range. Otherwise omit them to use the defaults (6am-5pm).

The script scans `~/.claude/history.jsonl` and session JSONL files for activity within the time window on the target date. It outputs JSON with per-session summaries: prompts, tool usage, files edited/created, git commits, and branches.

## Step 2b — Check for completed follow-ups

Read the follow-ups file:
```bash
source ~/.zprofile && obsidian read path="followups.md"
```

Scan for entries completed on the target date — look for sub-bullets matching `**Completed YYYY-MM-DD:**` where the date is the target standup date. These represent follow-ups the user closed that day, along with their notes about the outcome.

Collect the original follow-up item and its completion notes — these will be included in the standup as their own bullet(s) (e.g., "Followed up with Chris on PHP PR — tests pass, merged").

## Step 2c — Read PR notes

Read the PR notes file (created in Step 1 or already existing):
```bash
source ~/.zprofile && obsidian read path="reviews/YYYY-MM-DD.md"
```

PR reviews are real work — they should appear in the standup as their own bullet (e.g., "Reviewed PR #1234 — feedback on error handling in auth flow"). Authored PRs that received activity should also be noted.

## Step 2d — Read existing standup (CRITICAL for incremental synthesis)

Read the existing standup file for the target date:
```bash
source ~/.zprofile && obsidian read path="standup/YYYY-MM-DD.md"
```

The briefing skill (`/obsidian:briefing`) typically creates this file earlier in the day with `## Yesterday`, `## Today`, and `## Completed` sections. Throughout the day, `/obsidian:standup-add` appends completed work to the `## Completed` section in the user's own voice and detail level.

**When synthesizing for a day that already has a `## Completed` section, those items are LOCKED — they stay verbatim.** Do not rewrite, condense, re-word, or reorganize them. The user has already captured that work with the phrasing and detail they want.

Enumerate the existing Completed items. Your job in Step 3 is purely additive: find work from session data that is NOT already represented in the existing Completed section and propose ONLY those as new items.

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

Search for matches:
```bash
source ~/.zprofile && obsidian files folder="investigations"
source ~/.zprofile && obsidian files folder="decisions"
source ~/.zprofile && obsidian files folder="reviews"
```

**How to add links:**
- If a bullet mentions research that produced an investigation note: `[[investigations/YYYY-MM-DD-slug|React-First Migration]]`
- If a bullet references a decision: `[[decisions/YYYY-MM-DD-slug|decision]]`
- PR review/authored bullets: `[[reviews/YYYY-MM-DD]]`

Only add wikilinks where a real note exists — don't fabricate paths. Keep the bullet readable; the link should wrap a natural phrase, not be tacked on awkwardly.

## Step 4 — Write to Obsidian

Use the Obsidian CLI to write a per-day file. The CLI requires `source ~/.zprofile &&` before each `obsidian` command.

**File path:** `standup/YYYY-MM-DD.md` (e.g., `standup/2026-03-18.md`)

Check if the file already exists first:
```bash
source ~/.zprofile && obsidian read path="standup/YYYY-MM-DD.md"
```

If the file exists and has content, ask the user whether to overwrite or skip.

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
