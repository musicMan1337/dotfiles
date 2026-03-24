---
name: factory:patrol:ccusage
model: haiku
description: >
  ccusage cost patrol mode. Reads watcher.js state file, interprets token/cost
  alerts, and routes notifications through the factory system. Indefinite mode,
  designed for /loop. Triggers on: watch my usage, patrol ccusage, monitor token
  usage, cost patrol, usage sentinel, check my spend, token patrol, ccusage patrol
---

# Factory Patrol — ccusage Mode

Read `factory/patrol/SKILL_BASE.txt` and internalize the shared lifecycle before proceeding. This mode extends the base with Claude Code usage/cost monitoring via a pre-built watcher process.

## Architecture

This mode does **not** call ccusage directly. A separate background process (`watcher.js`) polls ccusage every 5 minutes and writes a state file. This patrol mode reads that file, deduplicates alerts against its own state, and routes notifications through `/factory:notify`.

```
watcher.js (background) → usage-state.json → this patrol mode → /factory:notify
```

**Watcher location:** `~/dotfiles/claude/commands/factory/patrol/ccusage/lib/ccusage-watcher.js`
**Start command:** `node ~/dotfiles/claude/commands/factory/patrol/ccusage/lib/ccusage-watcher.js`

## Constants

```
WATCHER_STATE = "~/.claude/ccusage-watcher/usage-state.json"
WATCHER_HISTORY = "~/.claude/ccusage-watcher/usage-history.jsonl"
WATCHER_LOG = "~/.claude/ccusage-watcher/watcher.log"
STATE_FILE = "ccusage-state.json"
OUTPUT_FILE = "ccusage-summary.md"
STALE_THRESHOLD_MINUTES = 10
```

## State Schema

Extends the base `last_run` with alert tracking and watcher health:

```json
{
  "last_run": "ISO-8601 | null",
  "alerts_processed": {
    "<type>:<sessionId|blockId>": {
      "first_seen": "ISO-8601",
      "last_seen": "ISO-8601",
      "times_seen": 1,
      "disposition": "notified|batched|suppressed"
    }
  },
  "daily_burn_notified": {
    "2026-03-24": true
  },
  "watcher_health": {
    "last_seen_alive": "ISO-8601",
    "consecutive_stale": 0,
    "warned_user": false
  }
}
```

## Mode Phases

### Phase 1 — Watcher Health Check

Read `~/.claude/ccusage-watcher/usage-state.json`. If the file:

- **Does not exist:** Log warning, notify user to start watcher (`node ~/dotfiles/claude/commands/factory/patrol/ccusage/lib/ccusage-watcher.js`), exit this cycle. No-op.
- **Exists but `lastUpdated` is >10 minutes stale:**
  - Increment `watcher_health.consecutive_stale`
  - If `warned_user` is false, warn once via `/factory:notify` (severity `info`): "ccusage watcher appears stopped — last poll was {N} minutes ago. Run `node ~/dotfiles/claude/commands/factory/patrol/ccusage/lib/ccusage-watcher.js` to restart."
  - Set `warned_user = true`. Suppress further warnings until watcher recovers.
  - Still process any existing alerts in the file (they may be recent enough to matter).
- **Exists and fresh:** Reset `consecutive_stale` to 0, set `warned_user = false`, update `last_seen_alive`.

### Phase 2 — Read & Classify Alerts

Read the state file **once** — do not re-read during this cycle.

Extract `newAlerts[]` and classify by severity:

| Severity   | Alert Types                            |
| ---------- | -------------------------------------- |
| **HIGH**   | `RUNAWAY_SESSION`, `BLOCK_COST_SPIKE`  |
| **MEDIUM** | `DAILY_BURN_RATE`, `OPUS_OVER_MODELED` |
| **LOW**    | `CACHE_MISS`                           |

### Phase 3 — Dedup Against Patrol State

The watcher deduplicates against its own previous snapshot, but alerts can persist across multiple watcher polls. This phase prevents patrol from re-notifying on the same alert.

For each alert in `newAlerts[]`, build a dedup key: `{type}:{sessionId|blockId}`

- **Already in `alerts_processed` with same `type` and ID:** Increment `times_seen`, update `last_seen`. Do NOT re-notify.
- **New (not in `alerts_processed`):** Add to processing queue. Create entry in `alerts_processed`.
- **Special case — `DAILY_BURN_RATE`:** Check `daily_burn_notified[today's date]`. If already true, suppress. Otherwise mark today as notified.

After dedup, you have a list of **genuinely new alerts** to act on.

### Phase 4 — Generate Summary

**Only generate output if there are new alerts or if the summary file doesn't exist yet.**

Write to `.factory/patrol/ccusage-summary.md` (snapshot, overwritten each run):

```markdown
# ccusage Summary — {YYYY-MM-DD HH:MM}

**30-day cost:** ${totalCost30d} | **Sessions:** {totalSessions30d} | **Tokens:** {totalTokens30d}
**Active block:** ${activeBlockCost} ({activeBlockId}) | **Watcher:** {healthy|stale|stopped}

---

## Model Distribution

| Model   | Sessions | Input Tokens | Output Tokens | Cost |
| ------- | -------- | ------------ | ------------- | ---- |
| {model} | {N}      | {N}          | {N}           | ${N} |

## Active Alerts

### HIGH

- {alert message with context}

### MEDIUM

- {alert message with context}

### LOW

- {alert message with context}

_(no alerts = "All clear.")_

## Top Sessions (by cost)

| Session     | Models   | Output Tokens | Cost | Last Activity   |
| ----------- | -------- | ------------- | ---- | --------------- |
| {sessionId} | {models} | {N}           | ${N} | {relative time} |

## 7-Day Trend

| Date   | Cost    |
| ------ | ------- |
| {date} | ${cost} |
```

**For OPUS_OVER_MODELED alerts**, include the estimated savings vs Sonnet from the alert data. This is the actionable insight — surface it prominently.

**For RUNAWAY_SESSION alerts**, include the suggestion: "Consider running /clear or starting a fresh session."

## Notify Threshold

Route notifications based on the genuinely new alerts (post-dedup):

- **`action-needed`** severity if any HIGH alert is new (`RUNAWAY_SESSION`, `BLOCK_COST_SPIKE`)
- **`info`** severity if 2+ MEDIUM alerts in this cycle (`DAILY_BURN_RATE`, `OPUS_OVER_MODELED`)
- **Silent** (no notify) if only LOW alerts or no new alerts

**Notify format:**

```
summary: "ccusage patrol: {brief — e.g., 'runaway session detected ($14.20)' or '2 medium alerts, daily burn rate warning'}"
severity: action-needed | info
source: patrol
links: [".factory/patrol/ccusage-summary.md"]
details: "{top 1-3 alert messages, one per line}"
```

## Hard Constraints

- **Never run ccusage directly.** Read from the watcher's state file only. The watcher handles all CLI interaction.
- **Never modify `~/.claude/ccusage-watcher/` files.** Those belong to the watcher process. Read-only access.
- **Read-only monitoring.** No branches, no fixes, no code changes. This mode creates awareness, not work.
- **DAILY_BURN_RATE fires once per day max.** Track in `daily_burn_notified` by date string. Even if the watcher fires this alert every 5 minutes, patrol notifies once.
- **Watcher-down warning fires once.** Don't nag on every loop cycle. Set `warned_user` and suppress until recovery.
- **Cap the summary at 10 top sessions.** The watcher already limits to 10, but enforce on the patrol side too.

## Gotchas

- **Watcher must be running separately.** This patrol mode is useless without it. If usage-state.json is missing or perpetually stale, the watcher isn't running. The startup health check catches this, but don't silently no-op forever — warn the user on first detection.
- **Double dedup is intentional.** The watcher deduplicates `newAlerts` against its previous snapshot (same type+sessionId). But if the same session keeps triggering RUNAWAY_SESSION across multiple watcher polls (cost keeps climbing), `newAlerts` will contain it again. Patrol's `alerts_processed` prevents re-notification for the same session.
- **Model name matching.** Model IDs change over time (`claude-opus-4-5`, `claude-opus-4-6-20250901`, etc.). When checking for Opus usage in the summary, match on substring `opus`, `sonnet`, `haiku` — never hardcode full model IDs.
- **usage-state.json can be large.** It contains 30 days of session data, model breakdowns, and alert history. Read it once per cycle into memory. Don't re-read it in later phases.
- **The watcher runs `npx ccusage@latest`.** If ccusage isn't installed or npx is unavailable, the watcher fails silently and writes nothing. The patrol mode sees this as a stale/missing state file.
- **Active block can be null.** Between billing blocks, `activeBlock` and `activeBlockCost` are null. Handle gracefully — show "No active block" in the summary, not an error.
- **History JSONL is append-only.** If you ever need trend data beyond the 7-day `recentDaily` in the state file, read `usage-history.jsonl`. But for normal patrol cycles, the state file has everything you need.
