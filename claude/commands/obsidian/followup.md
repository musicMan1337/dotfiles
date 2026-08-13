---
name: obsidian:followup
model: haiku
description: Track follow-up items in Obsidian — waiting on, blocked on, circle back. Triggers on: follow up, remind me, blocked on
---

# Follow-up Tracker

Add, view, or clear follow-up items in Obsidian. These are things you need to circle back on — waiting on someone, blocked items, things to check later.

## Input

**Request:** $ARGUMENTS

- **No args** → list all pending follow-ups
- **Adding:** "Chris needs to test the PHP PR by Thursday"
- **Clearing:** "done: Chris tested the PR" or "clear the DD followup"

## File location

All follow-ups live in a single file: `followups.md`

## No args — List pending follow-ups

Read the file and show all open items:
```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs read "followups.md"
```

Show only unchecked items (`- [ ]`). If any are past their date, flag them as **OVERDUE**. If there are none, say so.

## Adding a follow-up

Parse the user's input for: **what** needs to happen, **who** is involved (if anyone), and **when** (if a deadline was mentioned). Convert relative dates to absolute (e.g., "Thursday" → "2026-03-20").

Append to the file:
```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs append "followups.md" <<'EOF'
...
EOF
```

**Entry format:**
```
- [ ] [YYYY-MM-DD] Description — @person (if applicable) — [[context-link]]
```

**Linking context:** If the follow-up came from a specific investigation, decision, or standup, add a wikilink at the end. Search for relevant notes:
```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs search "<keywords>" --path investigations
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs search "<keywords>" --path decisions
```
Only add a link if a real match is found. Omit the `— [[...]]` suffix if there's nothing to link to.

If the file doesn't exist yet, create it:
```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs write "followups.md" <<'EOF'
# Follow-ups

- [ ] ...
EOF
```

### After adding — check for completed items

After successfully adding the new follow-up, **always read the full file back** and show the user all currently open items. Then ask: "Any of these done?" using AskUserQuestion with the open items as options (multiSelect: true), plus a "None — all still open" option.

For any items the user marks as done, toggle them from `- [ ]` to `- [x]` and rewrite the file.

## Completing a follow-up (explicit)

When the user says "done: ..." without adding anything new:

Read the file, find the matching item via fuzzy match, toggle `- [ ]` to `- [x]`, then rewrite:
```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs write "followups.md" <<'EOF'
...
EOF
```

## Completing a follow-up with notes

When the user says something like "I followed up on X, here's what happened: ..." or "followed up with Chris — he said Y", they're reporting the outcome of a follow-up. This is different from just marking it done.

1. Read the file and fuzzy-match the referenced follow-up item.
2. Toggle `- [ ]` to `- [x]`.
3. Add a completion sub-bullet directly below the original line with the date and the user's notes:

```
- [x] [2026-03-18] Chris needs to test the PHP PR by Thursday — @Chris
  - **Completed 2026-03-20:** Chris confirmed tests pass, merged the PR. No issues found.
```

4. Rewrite the file:
```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs write "followups.md" <<'EOF'
...
EOF
```

The completion sub-bullet format is: `  - **Completed YYYY-MM-DD:** <notes>` (two-space indent, today's date, then the user's follow-up notes in their own words).

## Gotchas

- **There is no `obsidian` CLI. Never call it.** The `obsidian` on PATH is the app binary (`/Applications/Obsidian.app/Contents/MacOS/obsidian`). It has no `create`/`read`/`append`/`search` subcommands: passing it `create path=... content=...` silently launches the app and leaves a stray `Untitled N.md` in the vault root, writing nothing. Vault access goes through `_lib/vault-cli.mjs` (or `_lib/gather.mjs` for the bundled reads).
- **Dates are critical.** Always include one — even if the user didn't specify, use today's date as "added on".
- **Don't over-organize.** One flat file is intentional. If it gets long, the user can clean it up. Don't create subfolders or split by category.
- **Fuzzy matching for completion.** When the user says "done: Chris PR", match it to the right item even if the wording doesn't match exactly.
- **Keep completed items in the file.** Don't delete them — just check the box. They serve as a history of what was resolved. (The standup skill will clean up completed-with-notes entries after consuming them.)
