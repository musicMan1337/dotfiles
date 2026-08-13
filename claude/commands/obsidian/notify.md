---
name: obsidian:notify
model: haiku
description: Write enriched notifications to Obsidian daily factory notes. Triggers on: factory note, factory notification
---

# Obsidian Factory Notification

Write an enriched notification entry to today's factory daily note in Obsidian. One note per day at `factory/YYYY-MM-DD.md`, append-only within the day.

## Input

Parse from the calling context:

- **summary**: What happened (1-3 sentences) — required
- **severity**: `info` | `warning` | `action-needed` | `error` — default `info`
- **source**: Which skill triggered this (`patrol`, `pipeline`, or `manual`) — default `manual`
- **links**: PR URLs, issue URLs, branch names, file paths — optional
- **details**: Longer context (audit results, error logs, triage breakdown) — optional
- **repo**: The repository name this relates to — infer from cwd if not provided

## Daily Note Path

`factory/YYYY-MM-DD.md` — use today's date.

## First Entry of the Day

If the note doesn't exist yet, create it with a header:

```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs write "factory/YYYY-MM-DD.md" <<'EOF'
# Factory Log — YYYY-MM-DD

---

EOF
```

## Append a Notification Entry

Format the entry as enriched markdown, then append:

```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs append "factory/YYYY-MM-DD.md" <<'EOF'
...
EOF
```

### Entry Format

```markdown

### {severity_icon} {source} — {headline} ({HH:MM})

{summary paragraph — 1-3 sentences, natural language}

{links block — only if links exist}
> **Links**
> - PR: [#123](url)
> - Issue: [#42](url)
> - Branch: `factory/patrol-fix-42`
> - Run: `20260321-143022-fix-login-bug`

{details block — only if details provided}
> [!details]- Details
> {collapsible details content — audit results, error snippets, triage breakdown}
> {use Obsidian callout syntax for collapsibility}

---
```

Severity → icon:
- `info` → `ℹ️`
- `warning` → `⚠️`
- `action-needed` → `🔔`
- `error` → `🚨`

### Enrichment Guidelines

This is NOT a flat log line — it's a note entry that a human will read in Obsidian. Enrich appropriately:

- **Links should be clickable** — use markdown link syntax for URLs, backtick-wrap branches and run IDs
- **Details use Obsidian callouts** — `> [!details]- Title` for collapsible sections, so the note stays scannable
- **Tag with source** — the `### heading` includes the source skill so you can visually scan what generated each entry
- **Time in heading** — include `HH:MM` so entries within a day have temporal context
- **Use wikilinks** — if referencing other Obsidian notes (e.g., investigations, follow-ups), use `[[note-name]]` syntax
- **Keep the summary readable** — write for a human glancing at Obsidian over coffee, not for machine parsing

## Reading Notifications (for other skills)

Other factory skills (patrol, pipeline) may read the notifications folder for context. Standard patterns:

```bash
# Read today's notifications
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs read "factory/YYYY-MM-DD.md"

# Search recent notifications
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs search "keyword" --path factory
```

## Gotchas

- **There is no `obsidian` CLI. Never call it.** The `obsidian` on PATH is the app binary (`/Applications/Obsidian.app/Contents/MacOS/obsidian`). It has no `create`/`read`/`append`/`search` subcommands: passing it `create path=... content=...` silently launches the app and leaves a stray `Untitled N.md` in the vault root, writing nothing. Vault access goes through `_lib/vault-cli.mjs` (or `_lib/gather.mjs` for the bundled reads).
- **Don't overwrite.** Always `append`, never `create` with `overwrite` on an existing daily note. Other entries from earlier in the day must be preserved.
- **Check before first create.** Before creating today's note, try to read it first. If it exists, just append. If it doesn't, create with header then append.
- **One note per day, not per notification.** Multiple notifications in a day all go into the same file, separated by `---` rules.
- **Obsidian callout syntax for details.** Use `> [!note]- Title` or `> [!details]- Title` — the `-` makes it collapsed by default so the daily note stays scannable even with many entries.
- **Don't duplicate.** If called twice with the same summary in the same minute, skip the second write. Check the existing note content first.
- **Keep entries self-contained.** Each entry should make sense on its own — don't reference "the previous entry" or assume reading order.
