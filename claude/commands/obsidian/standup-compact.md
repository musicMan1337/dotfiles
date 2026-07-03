---
name: obsidian:standup-compact
model: haiku
description: Compact a finalized standup into a concise top-section for posting, preserving the verbose original for reference. Triggers on: compact standup, summarize standup, shrink standup, condense standup, slack version
allowed-tools: Bash(source ~/.zprofile && obsidian *), Bash(node ~/.claude/commands/obsidian/_lib/gather.mjs *), Read
---

# Standup Compact

Add a concise `# Compacted` section at the **top** of a finalized standup file, distilled from the verbose numbered list below. The verbose original stays untouched — it's the source of truth for future reference. The compacted block is what gets posted to Slack/Teams.

## Input

**Request:** $ARGUMENTS

Date resolution (default: yesterday — most common case is "yesterday's standup wasn't posted yet"):
- No args → yesterday (Mon→Fri rollback)
- "today" → today
- "yesterday" → prior workday
- "friday" / "monday" / etc. → that weekday in the current week (or prior week if not yet reached)
- `YYYY-MM-DD` → that exact date

## Step 1 — Gather (resolve date + read + validate)

Run the gather script. It resolves the date (Mon→Fri rollback for "yesterday", weekday lookup), reads the standup file directly, and pre-computes the finalized/compacted checks:

```bash
node ~/.claude/commands/obsidian/_lib/gather.mjs --for compact [DATE]
```

`DATE` is the resolved token: omit for `yesterday` (default), or pass `today`, a weekday name, or `YYYY-MM-DD`. The script owns the date math; never guess a date. The bundle gives `date`, `weekday`, and `standup` (`{exists, content, isFinalized, hasCompactedSection}`).

If `standup.exists` is `false` → tell the user, stop.

## Step 2 — Validate finalized state (BLOCKING)

The standup MUST be finalized. Compaction is meaningless on raw work-in-progress files.

`standup.isFinalized` is already computed: `false` means the file still contains briefing `##` headers (`## Today`, `## Completed`, `## Yesterday`, `## Open Follow-ups`, `## Active Investigations`, `## PRs Awaiting Your Review`, `## Your Open PRs`). A finalized standup is a flat numbered list (`1. **...**` items with sub-bullets, no level-2 headers).

**If `standup.isFinalized` is `false`, reject and stop:**

> "Standup YYYY-MM-DD isn't finalized yet, still has `## Today` / `## Completed` sections. Run `/obsidian:standup` on this date first to synthesize it down."

## Step 3 — Check for existing Compacted section

If `standup.hasCompactedSection` is `true` (file already starts with `# Compacted`), ask the user:

```
Standup YYYY-MM-DD already has a # Compacted section.

1. Regenerate (overwrite the existing compacted block)
2. Skip
```

If 2, stop. Don't write.

## Step 4 — Generate the compacted version

Read every numbered item in the original. For each:
- Identify the **major work threads** — group related sub-bullets into themes (architecture, perf, docs, validation, etc.)
- Each major item gets **2–4 sub-bullets** in the compacted version (occasionally 1 if it's a small item, occasionally 5 if it's a huge one). Not a flat one-liner.
- Keep PR numbers, branch names, and case IDs — they're load-bearing.
- Keep concrete signal that makes the line readable: file paths when load-bearing, percentages and metric deltas, key function/component names. Drop ceremony (option-2 view pattern names, exhaustive sub-attribute lists).
- **Cut low-signal sub-bullets entirely.** Folder moves, namespace updates, lint config tweaks, doc-only style changes — these don't earn a line in a posted standup. If it was just "moved a thing" or "renamed a thing in five places," drop it.
- **Combine related fixes** into one sub-bullet with a semicolon or em-dash. Three sub-bullets that all configure the same docker-compose file should fuse into "Login fixes: A, B".

**Format per item:**
```
- **Project/Feature** (branch → PR #NNNN)
  - Theme 1 — brief description of outcome (with key metric/path if it matters)
  - Theme 2 — brief description of outcome
  - Theme 3 — brief description of outcome
```

Variations:
- No PR yet → `(branch)` or `(no branch)`
- Multiple PRs in one item → `(branch → PR #A, #B)` or `(branch-A → PR #A, branch-B → PR #B)`
- Investigations/diagnoses with no shipping artifact → `(diagnosis, no branch)` or `(no branch)`

**Style guide:**
- Outcome-focused, not action-focused. "Fixed X" not "investigated and fixed X".
- Sub-bullets are short clauses, not full prose paragraphs. Past tense, terse. Drop articles when meaning survives.
- Concrete > abstract. "Pinned bsqldev DNS in compose" beats "improved Docker networking".
- If a sub-bullet runs past ~30 words, you're including too much — split a sub-thread out or trim.
- The compacted version should be ~25–35% the size of the original. Smaller is fine if the day was a single thing; bigger means you didn't cut enough.

## Step 5 — Show preview and get approval

Display the compacted block as a code block, not interleaved with prose. Then:

```
1. Approve — write it
2. Regenerate — different angle/wording
3. Skip — don't write
```

Wait for user reply. Do NOT write until approved.

## Step 6 — Write back

Build the full new file content:

```
# Compacted

- **...** (...)
  - ...
  - ...
- **...** (...)
  - ...

---

<original content verbatim — every numbered item, every sub-bullet, every word>
```

The `---` separator visually delimits compacted from original.

Write via:

```bash
source ~/.zprofile && obsidian create path="standup/YYYY-MM-DD.md" overwrite content="..."
```

End with "Done." — no recap.

## Gotchas

- **Preserve original verbatim.** Never edit a single character of the original numbered list — even fixing a typo. Future-you treats it as the canonical record.
- **PR/branch references are mandatory.** A compacted bullet without its PR# is useless for posting. If the original has no PR/branch, mark it `(no branch)` or `(diagnosis)` so the reader knows it's intentional.
- **Don't bundle unrelated items.** Tempting to merge "CI4 cleanup" and "CI4 logging" into one line, but they're separate work tracks. Keep one bullet per original numbered item — that's the natural unit.
- **The original may already be long because the day was big.** Don't apologize for a long compacted list — a 4-item standup with 16 verbose sub-bullets still gets 4 compacted items, each with 2–4 sub-bullets. The win is theme grouping + cutting low-signal items, not item-count reduction.
- **"Compacted" goes at the top because that's what people read first.** Don't put it at the bottom or wrap it in a collapsible. The whole point is "the part you post" lives above the fold.
- **Sub-bullets ARE the constraint, not single lines.** A flat one-liner per item loses too much context; 6 verbose sub-bullets defeats the purpose. Aim for 2–4 sub-bullets per major item, each a short clause. If you have 8 sub-bullets in the original, you should be grouping them into ~3 themes.
- **Drop low-signal sub-bullets without apology.** Folder moves, namespace updates, lint config tweaks, doc-only style changes, "renamed a thing in five places" — none of these earn a sub-bullet in the compacted version. The original keeps them; the post doesn't need them.
- **Don't add new information.** If the original doesn't mention a metric, don't infer one from context. Compaction = subset, never superset.
