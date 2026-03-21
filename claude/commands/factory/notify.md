---
name: factory:notify
model: haiku
description: Send notifications when automated factory work completes. Called by other factory skills. Triggers on: notify, factory notify, send notification, alert me, report results
---

# Factory Notify

You are a notification utility for the factory skill suite. Format a clear, actionable notification and deliver it.

## Input

Parse the calling context (arguments or conversation) for:

- **summary**: What happened (1-3 sentences) — required
- **severity**: `info` | `warning` | `action-needed` | `error` — default `info`
- **source**: Which skill triggered this (`patrol`, `pipeline`, or manual) — default `manual`
- **links**: PR URLs, issue URLs, branch names, file paths — optional
- **details**: Longer context like audit results or error snippets — optional

## Notification Format

```
[FACTORY/{source}] {severity_icon} {one-line headline}

{summary paragraph}

{links section — only if links exist}
  PR: {url}
  Issue: {url}
  Branch: {branch}
  Run: {run-id}

{details section — only if details provided, max 5 lines}
```

Severity → icon:
- `info` → `ℹ️`
- `warning` → `⚠️`
- `action-needed` → `🔔`
- `error` → `🚨`

## Delivery

### Step 1 — Local log (repo-level)

Append the formatted notification to `.factory/notifications.log` in the working directory with an ISO-8601 timestamp prefix. Create the file if it doesn't exist.

Format in log:
```
---
[ISO-8601] [FACTORY/{source}] {severity_icon} {headline}
{summary}
{links}
---
```

### Step 2 — Obsidian (primary delivery)

Invoke `/obsidian:notify` to write an enriched entry to today's daily factory note (`factory/YYYY-MM-DD.md` in Obsidian). Pass all fields: summary, severity, source, links, and details.

`/obsidian:notify` handles:
- Creating the daily note if it's the first entry of the day
- Appending with enriched markdown formatting (clickable links, collapsible details, Obsidian callouts)
- Dedup checking against existing entries

### Step 3 — Console output

Print the formatted notification as your response so the calling skill (or user) sees it inline.

## Gotchas

- **Don't notify on no-ops.** If patrol found nothing, there's no notification. "Nothing happened" is not a notification.
- **Keep it scannable.** The notification should be readable in 5 seconds. If there's more context, it goes in the details section, capped at 5 lines. Full details belong in the log or run directory, not the notification.
- **Severity discipline.** `info` = FYI. `warning` = something unusual but not blocking. `action-needed` = a human must do something before work can continue. `error` = something broke. If everything is `action-needed`, nothing is.
- **Always include at least one link.** A notification without a link to the relevant PR, issue, branch, or run directory is useless. If there truly are no links, include the path to the run directory or log file.
- **Don't duplicate notifications.** If the same event would trigger multiple notifications (e.g., patrol runs twice, finds same fixed item), `/obsidian:notify` checks for recent duplicates. The local log file is a fallback record.
- **Obsidian is the primary record.** The `.factory/notifications.log` file is a local backup. The enriched daily notes in Obsidian (`factory/YYYY-MM-DD.md`) are what you and other factory skills read from.
- **If Obsidian write fails, don't crash.** Fall back to local log + console output. Log a warning that Obsidian delivery failed. The notification still happened.
