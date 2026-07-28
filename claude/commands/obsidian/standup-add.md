---
name: obsidian:standup-add
model: haiku
description: Add completed work to today's standup and clear matching briefing TODOs. Triggers on: add to standup, mark done, log work
allowed-tools: Bash(source ~/.zprofile && obsidian *), Bash(node ~/.claude/commands/obsidian/_lib/gather.mjs *), Read
---

# Standup Add

Append completed work to a standup note. If the note still has briefing structure (`## Today`, `## Completed`), work within that structure. If the note is already a flat numbered list (completed standup), append new items to the end of the list.

## Input

**Request:** $ARGUMENTS

- No args → synthesize what was done in the **current session**, add to today's standup
- A date (e.g., "yesterday", "2026-04-10") → target that day's standup
- Specific text (e.g., "finished the auth middleware refactor") → add that verbatim
- Both combined: "yesterday finished the auth refactor"

## Step 1 — Gather + determine content

Run the gather script to resolve the date and pull the existing standup + wikilink targets in one call (reads the vault directly, no `obsidian read`/`obsidian files`):

```bash
node ~/.claude/commands/obsidian/_lib/gather.mjs --for add [DATE]
```

`DATE` is the resolved token: `today` (default), `yesterday`, a weekday name, or `YYYY-MM-DD`. The script owns the date math; never guess. The bundle gives `date`, `standup` (`{exists, content}`), and `wikilinkTargets`.

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

## Step 2 — Inspect the existing standup

Use `standup` from the gather bundle (Step 1). If `standup.exists` is `false`, create one as a flat numbered list (no section headings).

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

Before finalizing, check if completed items reference existing Obsidian notes. Use `wikilinkTargets` from the gather bundle (Step 1), no extra calls.

Add inline wikilinks where real notes exist, same convention as the standup skill:
- PR review work: `[[reviews/YYYY-MM-DD]]`
- Investigation: `[[investigations/YYYY-MM-DD-slug|name]]`
- Decision: `[[decisions/YYYY-MM-DD-slug|name]]`

### External-reference links (cases, PRs, artifacts)

Wikilinks above are for internal Obsidian notes. Anything outside the vault gets a normal markdown link so the note is click-through. Only ever link a real target; never fabricate a URL.

- **Case system numbers** (Viper `caseid`): link the number as `[353105](https://my.ebacon.com/index.php/viper/#caseSystem/353105)`. In a header, `**Case [353105](https://my.ebacon.com/index.php/viper/#caseSystem/353105) - description**`. Every case ID resolves to this URL by construction, so always link it.
- **PR numbers**: `[Repo #NUMBER](html_url)` using the PR's real `html_url` (e.g. `[Viper #9914](https://github.com/TAGEmployerServices/Viper/pull/9914)`), never a bare `#9914`.
- **Artifacts, dashboards, other URLs**: wrap the reference in a markdown link whenever you have the URL; never paste a bare URL or mention it link-less.

## Step 5 — Show draft and get approval

Show the user a **focused diff**, not the entire file:
1. Any TODO items that will be struck through (show before → after)
2. The new/updated completed items
3. If existing completed items were merged with new content, show the merged result

**Do not write until the user confirms.** This is a hard gate.

## Step 6 — Re-gather, merge, then write

Other sessions write to the same standup note; the Step 1 snapshot may be stale by the time the user approves. `overwrite` clobbers whatever landed in between. So, immediately before writing:

1. **Re-run the gather script** (same command as Step 1) and compare against the Step 1 snapshot.
2. **Content changed since Step 1:** rebase your additions onto the CURRENT content: re-apply the strike-throughs and append the Completed items to the fresh version. Never write from the stale snapshot; that silently deletes another session's work.
3. **Idempotency check:** if the fresh content already contains your items (same PR number, branch, or feature: an earlier invocation this session, or another session, already logged it), skip the write entirely and tell the user it's already there. Do not create a second entry and do not rewrite the file just to change wording.

Then write:

```bash
source ~/.zprofile && obsidian create path="standup/YYYY-MM-DD.md" content="..." overwrite
```

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Concurrent sessions are the norm, not the edge case.** Multiple Claude sessions add to the same day's standup; the Step 6 re-gather + merge is mandatory. Blind overwrite from a stale read has caused real data loss.
- **Double invocation happens.** The skill gets invoked twice for the same work (retry, habit, chained ritual). The second run must detect the existing entry via the Step 6 idempotency check and no-op with a note, never duplicate.
- **Don't duplicate completed items.** If the same work already appears in Completed, enrich it with new sub-bullets — don't create a second entry.
- **Fuzzy matching is judgment, not string matching.** "Review Alex's resource PR" and "Reviewed PR #9248 resource budgeting" are the same thing. PR numbers and branch names are the most reliable match signals.
- **Current session synthesis — outcomes only.** "Fixed auth bug" not "Read 12 files and edited 3". Tool usage counts are never standup-worthy.
- **Preserve all other content.** Only touch TODO strike-throughs and the Completed section. Everything else stays exactly as-is.
- **Today section format varies.** The briefing skill writes numbered bullets, but the user may have edited them manually. Don't assume exact formatting — scan for semantic matches regardless of bullet style.
