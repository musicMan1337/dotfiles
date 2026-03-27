#!/usr/bin/env node

/**
 * ccusage-watcher
 * Polls ccusage every N minutes and writes a single usage-state.json
 * that a CC patrol agent can read and act on.
 */

import { execSync } from "child_process"
import { writeFileSync, readFileSync, existsSync, mkdirSync } from "fs"
import { join, dirname } from "path"
import { homedir } from "os"

// ─── Config ──────────────────────────────────────────────────────────────────
const args = process.argv.slice(2)
const pollIntervalMs = args[0] ? parseInt(args[0]) : 0

const POLL_INTERVAL_MS = pollIntervalMs || 5 * 60 * 1000 // 5 minutes
const OBSIDIAN_CCUSAGE_DIR = join(
  homedir(),
  ".obsidian-vault",
  "factory",
  "ccusage",
)
const STATE_FILE = join(OBSIDIAN_CCUSAGE_DIR, "usage-state.json")
const HISTORY_FILE = join(OBSIDIAN_CCUSAGE_DIR, "usage-history.jsonl")
const LOG_FILE = join(OBSIDIAN_CCUSAGE_DIR, "watcher.log")

// Thresholds — patrol agent uses these too, keep in sync with SKILL.md
const THRESHOLDS = {
  // Cost spike: current 5-min block cost increased by more than this vs previous snapshot
  blockCostSpikeDelta: 10.0, // $10 increase in one poll cycle = spike
  // Opus abuse: session used opus but output was tiny
  opusLowOutputTokens: 6000, // flag opus sessions with < 6k output tokens
  // Cache miss: large input with almost no cache reads
  cacheMissInputThreshold: 80000, // flag sessions with >80k input...
  cacheMissReadRatio: 0.05, // ...but <5% cache read ratio
  // Runaway session: single session cost exceeded this
  runawaySessionCost: 100.0, // $100 in one session (Pro plan — heavy usage is normal)
  // Daily burn rate: on pace to exceed this by end of day
  dailyBurnWarning: 100.0, // warn at $100/day pace (7d avg ~$68)
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}`
  console.log(line)
  try {
    const existing = existsSync(LOG_FILE) ? readFileSync(LOG_FILE, "utf8") : ""
    const lines = existing.split("\n").filter(Boolean)
    // Keep last 500 log lines
    lines.push(line)
    const trimmed = lines.slice(-500).join("\n") + "\n"
    writeFileSync(LOG_FILE, trimmed)
  } catch {}
}

function ensureDirs() {
  const dir = dirname(STATE_FILE)
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
}

function runCcusage(args) {
  try {
    const raw = execSync(`npx ccusage@latest ${args} --json`, {
      timeout: 30000,
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
    })
    return JSON.parse(raw.trim())
  } catch (err) {
    log(`WARN: ccusage ${args} failed: ${err.message?.split("\n")[0]}`)
    return null
  }
}

function getSince30Days() {
  const d = new Date()
  d.setDate(d.getDate() - 30)
  return d.toISOString().slice(0, 10).replace(/-/g, "")
}

// ─── Analysis ────────────────────────────────────────────────────────────────

function analyzeAlerts(sessions, daily, blocks, prevState) {
  const alerts = []
  const now = new Date().toISOString()

  // 1. Runaway session cost
  for (const s of sessions?.sessions ?? []) {
    if ((s.totalCost ?? 0) >= THRESHOLDS.runawaySessionCost) {
      alerts.push({
        type: "RUNAWAY_SESSION",
        severity: "HIGH",
        sessionId: s.sessionId,
        cost: s.totalCost,
        models: s.modelsUsed,
        outputTokens: s.outputTokens,
        message: `Session ${s.sessionId} cost $${s.totalCost?.toFixed(2)} — exceeds $${THRESHOLDS.runawaySessionCost} threshold`,
        detectedAt: now,
      })
    }
  }

  // 2. Opus used on low-output session (over-modeled)
  for (const s of sessions?.sessions ?? []) {
    for (const m of s.modelBreakdowns ?? []) {
      if (
        (m.modelName ?? m.model)?.includes("opus") &&
        (s.outputTokens ?? 0) < THRESHOLDS.opusLowOutputTokens &&
        (m.totalCost ?? 0) > 0.5 // only flag if it actually cost something meaningful
      ) {
        alerts.push({
          type: "OPUS_OVER_MODELED",
          severity: "MEDIUM",
          sessionId: s.sessionId,
          model: m.modelName ?? m.model,
          outputTokens: s.outputTokens,
          opusCost: m.totalCost,
          estimatedSonnetCost: parseFloat(
            (s.inputTokens * 0.000003 + s.outputTokens * 0.000015).toFixed(4),
          ),
          message: `Session ${s.sessionId} used ${m.model} but only generated ${s.outputTokens?.toLocaleString()} output tokens. Sonnet likely sufficient.`,
          detectedAt: now,
        })
      }
    }
  }

  // 3. Cache miss on large sessions
  for (const s of sessions?.sessions ?? []) {
    const input = s.inputTokens ?? 0
    const cacheRead = s.cacheReadTokens ?? 0
    const ratio = input > 0 ? cacheRead / input : 1
    if (
      input >= THRESHOLDS.cacheMissInputThreshold &&
      ratio < THRESHOLDS.cacheMissReadRatio
    ) {
      alerts.push({
        type: "CACHE_MISS",
        severity: "LOW",
        sessionId: s.sessionId,
        inputTokens: input,
        cacheReadTokens: cacheRead,
        cacheReadRatio: parseFloat(ratio.toFixed(3)),
        message: `Session ${s.sessionId} had ${input.toLocaleString()} input tokens but only ${(ratio * 100).toFixed(1)}% cache reads — context not being cached efficiently`,
        detectedAt: now,
      })
    }
  }

  // 4. Active block cost spike (compare to previous snapshot)
  const activeBlock = blocks?.blocks?.find((b) => b.isActive)
  if (activeBlock && prevState?.activeBlock) {
    const delta =
      (activeBlock.totalCost ?? 0) - (prevState.activeBlock.totalCost ?? 0)
    if (delta >= THRESHOLDS.blockCostSpikeDelta) {
      alerts.push({
        type: "BLOCK_COST_SPIKE",
        severity: "HIGH",
        blockId: activeBlock.blockId,
        prevCost: prevState.activeBlock.totalCost,
        currentCost: activeBlock.totalCost,
        deltaCost: parseFloat(delta.toFixed(4)),
        message: `Active billing block cost jumped +$${delta.toFixed(2)} in the last 5 minutes`,
        detectedAt: now,
      })
    }
  }

  // 5. Daily burn rate warning
  const today = new Date().toISOString().slice(0, 10)
  const todayEntry = daily?.daily?.find((d) => d.date === today)
  if (todayEntry) {
    const hourOfDay = new Date().getHours() + new Date().getMinutes() / 60
    if (hourOfDay > 0) {
      const pace = (todayEntry.totalCost / hourOfDay) * 24
      if (pace >= THRESHOLDS.dailyBurnWarning) {
        alerts.push({
          type: "DAILY_BURN_RATE",
          severity: "MEDIUM",
          todayCost: todayEntry.totalCost,
          projectedDailyCost: parseFloat(pace.toFixed(2)),
          message: `On pace for $${pace.toFixed(2)} today (currently $${todayEntry.totalCost?.toFixed(2)} at hour ${hourOfDay.toFixed(1)})`,
          detectedAt: now,
        })
      }
    }
  }

  return alerts
}

// ─── Main poll loop ───────────────────────────────────────────────────────────

async function poll() {
  log("Polling ccusage...")
  ensureDirs()

  let prevState = null
  if (existsSync(STATE_FILE)) {
    try {
      prevState = JSON.parse(readFileSync(STATE_FILE, "utf8"))
    } catch {}
  }

  // Gather data
  const since30 = getSince30Days()
  const [sessions, daily, monthly, blocks] = [
    runCcusage(`session --breakdown --since ${since30}`),
    runCcusage(`daily --breakdown --since ${since30}`),
    runCcusage("monthly --breakdown"),
    runCcusage("blocks"),
  ]

  if (!sessions && !daily) {
    log("WARN: All ccusage calls failed, skipping this cycle")
    return
  }

  // Active block summary
  const activeBlock = blocks?.blocks?.find((b) => b.isActive) ?? null

  // Model distribution across all sessions
  const modelTotals = {}
  for (const s of sessions?.sessions ?? []) {
    for (const m of s.modelBreakdowns ?? []) {
      const modelKey = m.modelName ?? m.model ?? "unknown"
      if (!modelTotals[modelKey]) {
        modelTotals[modelKey] = {
          sessions: 0,
          inputTokens: 0,
          outputTokens: 0,
          cost: 0,
        }
      }
      modelTotals[modelKey].sessions++
      modelTotals[modelKey].inputTokens += m.inputTokens ?? 0
      modelTotals[modelKey].outputTokens += m.outputTokens ?? 0
      modelTotals[modelKey].cost += m.totalCost ?? 0
    }
  }

  // Top 10 most expensive sessions
  const topSessions = [...(sessions?.sessions ?? [])]
    .sort((a, b) => (b.totalCost ?? 0) - (a.totalCost ?? 0))
    .slice(0, 10)
    .map((s) => ({
      sessionId: s.sessionId,
      models: s.modelsUsed,
      inputTokens: s.inputTokens,
      outputTokens: s.outputTokens,
      totalCost: s.totalCost,
      lastActivity: s.lastActivity,
    }))

  // Run alert analysis
  const alerts = analyzeAlerts(sessions, daily, blocks, prevState)
  const newAlerts = alerts.filter((a) => {
    // Deduplicate: don't re-fire same alert type+session within last poll window
    const prevAlerts = prevState?.alerts ?? []
    return !prevAlerts.some(
      (p) => p.type === a.type && p.sessionId === a.sessionId,
    )
  })

  // Build state object
  const state = {
    lastUpdated: new Date().toISOString(),
    pollIntervalMinutes: 5,
    thresholds: THRESHOLDS,
    summary: {
      totalCost30d: sessions?.totals?.totalCost ?? 0,
      totalSessions30d: sessions?.sessions?.length ?? 0,
      totalTokens30d: sessions?.totals?.totalTokens ?? 0,
      activeBlockCost: activeBlock?.totalCost ?? null,
      activeBlockId: activeBlock?.blockId ?? null,
    },
    modelDistribution: modelTotals,
    topSessions,
    activeBlock,
    alerts, // all current alerts
    newAlerts, // only alerts not seen in previous snapshot
    monthly: monthly?.monthly ?? [],
    recentDaily: (daily?.daily ?? []).slice(-7), // last 7 days
  }

  // Write state file (patrol agent reads this)
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2))
  log(`State written to ${STATE_FILE}`)

  // Append to history JSONL for trend analysis
  writeFileSync(
    HISTORY_FILE,
    JSON.stringify({
      ts: state.lastUpdated,
      totalCost30d: state.summary.totalCost30d,
      activeBlockCost: state.summary.activeBlockCost,
      alertCount: alerts.length,
      newAlertCount: newAlerts.length,
    }) + "\n",
    { flag: "a" },
  )

  // Console summary
  if (newAlerts.length > 0) {
    log(`⚠️  ${newAlerts.length} new alert(s):`)
    for (const a of newAlerts) {
      log(`  [${a.severity}] ${a.type}: ${a.message}`)
    }
  } else {
    log(
      `✓ No new alerts. Total cost (30d): $${state.summary.totalCost30d?.toFixed(2)}`,
    )
  }
}

// ─── Boot ─────────────────────────────────────────────────────────────────────

log("ccusage-watcher starting (interval: 5 min)")
log(`State file: ${STATE_FILE}`)
ensureDirs()

// Run immediately on start, then every 5 min
poll().catch((e) => log(`ERROR: ${e.message}`))
setInterval(
  () => poll().catch((e) => log(`ERROR: ${e.message}`)),
  POLL_INTERVAL_MS,
)
