---
name: obsidian:standup-add
model: haiku
description: Add completed work to today's standup and clear matching briefing TODOs. Triggers on: add to standup, mark done, log work
allowed-tools: Bash(source ~/.zprofile && obsidian *), Read
---

# Standup Add

Append completed work to a standup note. If the note still has briefing structure (`## Today`, `## Completed`), work within that structure. If the note is already a flat numbered list (completed standup), append new items to the end of the list.

## Input

**Request:** $ARGUMENTS

- No args → synthesize what was done in the **current session**, add to today's standup
- A date (e.g., "yesterday", "2026-04-10") → target that day's standup
- Specific text (e.g., "finished the auth middleware refactor") → add that verbatim
- Both combined: "yesterday finished the auth refactor"

## Step 1 — Determine target date and content

Resolve date. Default: today.

### Current session mode (no specific content provided)

Extract accomplishments from the current conversation. Priority signals:
1. **Commits made** — strongest signal, already describe completed work
2. **Branch name** — encodes ticket/feature context (e.g., `Derek/334513-PROSyncing`)
3. **User prompts** — what they asked for reveals intent
4. **Files edited** — scope of changes, but only interesting as context for the above
5. **Skills invoked** — PR reviews, investigations, decisions are real work items

Synthesize into outcome-focused bullets. "Fixed auth middleware token expiry bug" not "Edited 3 files in auth module". Same style as the standup skill — what a team lead cares about.

### User-provided content

Use their description as-is, lightly formatted into bullets if needed.

## Step 2 — Read existing standup

```bash
source ~/.zprofile && obsidian read path="standup/YYYY-MM-DD.md"
```

If no standup file exists, create one as a flat numbered list (no section headings).

## Step 3 — Match and strike through TODOs

If the standup has a `## Today` section, fuzzy-match its bullets against the completed work.

Match signals (any of these is sufficient):
- Same PR number
- Same branch name
- Same feature/project keywords
- Same ticket number from branch name

For each match: strike through the TODO → `~~original text~~`

**When unsure if a TODO matches, ask the user.** Don't silently skip ambiguous matches.

## Step 4 — Build the Completed section

**If `## Completed` already exists:**
- Check existing items for overlap (same PR, feature, branch)
- Overlap → append sub-bullets to existing item (don't duplicate)
- No overlap → append new items after existing ones

**If no `## Completed` section:**
- Add at bottom, separated by `---`

**Format:**
```markdown
---
## Completed

1. **Project/Feature** (branch-or-context)
   - Outcome-focused bullet
   - Another bullet if needed
```

### Wikilinks

Before finalizing, check if completed items reference existing Obsidian notes:
```bash
source ~/.zprofile && obsidian files folder="investigations"
source ~/.zprofile && obsidian files folder="decisions"
source ~/.zprofile && obsidian files folder="reviews"
```

Add inline wikilinks where real notes exist — same convention as the standup skill:
- PR review work: `[[reviews/YYYY-MM-DD]]`
- Investigation: `[[investigations/YYYY-MM-DD-slug|name]]`
- Decision: `[[decisions/YYYY-MM-DD-slug|name]]`

## Step 5 — Show draft and get approval

Show the user a **focused diff**, not the entire file:
1. Any TODO items that will be struck through (show before → after)
2. The new/updated completed items
3. If existing completed items were merged with new content, show the merged result

**Do not write until the user confirms.** This is a hard gate.

## Step 6 — Write to Obsidian

```bash
source ~/.zprofile && obsidian create path="standup/YYYY-MM-DD.md" content="..." overwrite
```

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Don't duplicate completed items.** If the same work already appears in Completed, enrich it with new sub-bullets — don't create a second entry.
- **Fuzzy matching is judgment, not string matching.** "Review Alex's resource PR" and "Reviewed PR #9248 resource budgeting" are the same thing. PR numbers and branch names are the most reliable match signals.
- **Current session synthesis — outcomes only.** "Fixed auth bug" not "Read 12 files and edited 3". Tool usage counts are never standup-worthy.
- **Preserve all other content.** Only touch TODO strike-throughs and the Completed section. Everything else stays exactly as-is.
- **Today section format varies.** The briefing skill writes numbered bullets, but the user may have edited them manually. Don't assume exact formatting — scan for semantic matches regardless of bullet style.
