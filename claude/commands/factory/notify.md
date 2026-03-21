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

### Step 1 — Always: Write to log

Append the formatted notification to `.factory/notifications.log` with an ISO-8601 timestamp prefix. Create the file if it doesn't exist.

Format in log:
```
---
[ISO-8601] [FACTORY/{source}] {severity_icon} {headline}
{summary}
{links}
---
```

### Step 2 — Deliver

<!-- TODO: Plug in actual notification delivery here.

     When ready to implement, add delivery config to .factory/config.json:
     {
       "notify": {
         "method": "log-only",
         "config": {}
       }
     }

     Planned delivery methods:

     1. Obsidian — Write to daily note or inbox
        - Use the obsidian skills to append to a factory inbox note
        - Config: { "method": "obsidian", "config": { "vault": "...", "note": "Factory Inbox" } }

     2. Slack — Post to a webhook
        - curl -X POST -H 'Content-type: application/json' --data '{"text":"..."}' $SLACK_WEBHOOK_URL
        - Config: { "method": "slack", "config": { "webhook_env": "SLACK_WEBHOOK_URL" } }

     3. Telegram — Send via bot API
        - curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d "chat_id=${TELEGRAM_CHAT_ID}" -d "text=..."
        - Config: { "method": "telegram", "config": { "token_env": "TELEGRAM_BOT_TOKEN", "chat_id_env": "TELEGRAM_CHAT_ID" } }

     4. GitHub — Comment on the relevant issue/PR
        - gh issue comment <number> --body "..."  or  gh pr comment <number> --body "..."
        - Config: { "method": "github", "config": { "comment_on": "issue|pr" } }

     5. Email — via sendmail, SMTP, or API
        - Config: { "method": "email", "config": { "to": "...", "from": "..." } }

     Implementation pattern:
     1. Read .factory/config.json for notify.method
     2. Switch on method, call the appropriate delivery
     3. Fall back to log-only if method not configured or delivery fails
-->

**Current behavior:** Log file + console output only. The log file at `.factory/notifications.log` is the persistent record.

Print the formatted notification as your response so the calling skill (or user) sees it.

## Gotchas

- **Don't notify on no-ops.** If patrol found nothing, there's no notification. "Nothing happened" is not a notification.
- **Keep it scannable.** The notification should be readable in 5 seconds. If there's more context, it goes in the details section, capped at 5 lines. Full details belong in the log or run directory, not the notification.
- **Severity discipline.** `info` = FYI. `warning` = something unusual but not blocking. `action-needed` = a human must do something before work can continue. `error` = something broke. If everything is `action-needed`, nothing is.
- **Always include at least one link.** A notification without a link to the relevant PR, issue, branch, or run directory is useless. If there truly are no links, include the path to the run directory or log file.
- **Don't duplicate notifications.** If the same event would trigger multiple notifications (e.g., patrol runs twice, finds same fixed item), check the log first. Recent duplicate = skip.
- **The log file grows forever.** That's fine. It's append-only by design. Cleanup is a separate concern.
