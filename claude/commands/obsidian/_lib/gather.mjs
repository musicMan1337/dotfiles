#!/usr/bin/env node

/**
 * One deterministic call that fetches everything an obsidian:* standup-family
 * skill needs, so the model never issues fragile per-file `obsidian read`
 * calls or computes dates itself. Outputs a single JSON bundle to stdout.
 *
 * Usage:
 *   node gather.js --for standup  [DATE] [--start HH] [--end HH]
 *   node gather.js --for briefing
 *   node gather.js --for add      [DATE]
 *   node gather.js --for compact  [DATE]
 *
 * DATE: today | yesterday | monday..friday | YYYY-MM-DD
 *   standup/add default = today, compact default = yesterday,
 *   briefing always reports both today and yesterday.
 */

import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import {
  resolveVault,
  readVaultFile,
  listFolder,
  resolveDate,
  isFinalizedStandup,
  extractCompletedBlock,
  uncheckedFollowups,
  completedForDate,
  activeInvestigations,
} from "./vault.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const EXTRACT_SESSIONS = path.resolve(HERE, "../standup/lib/extract-sessions.js");

// ---- arg parsing ------------------------------------------------------------

const argv = process.argv.slice(2);
let mode = null;
let dateToken;
let startHour;
let endHour;

for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === "--for") mode = argv[++i];
  else if (a === "--start") startHour = argv[++i];
  else if (a === "--end") endHour = argv[++i];
  else if (!a.startsWith("--")) dateToken = a;
}

if (!mode) {
  console.error("gather.js: missing --for <standup|briefing|add|compact>");
  process.exit(2);
}

// ---- section builders -------------------------------------------------------

function standupFile(date) {
  const f = readVaultFile(`standup/${date}.md`);
  return {
    ...f,
    isFinalized: isFinalizedStandup(f.content),
    completedBlock: extractCompletedBlock(f.content),
    hasCompactedSection: !!f.content && f.content.trimStart().startsWith("# Compacted"),
  };
}

function wikilinkTargets() {
  return {
    investigations: listFolder("investigations"),
    decisions: listFolder("decisions"),
    reviews: listFolder("reviews"),
  };
}

function runSessions(date) {
  const args = [EXTRACT_SESSIONS, date];
  if (startHour != null) args.push("--start", String(startHour));
  if (endHour != null) args.push("--end", String(endHour));
  try {
    const out = execFileSync("node", args, { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
    return JSON.parse(out);
  } catch (e) {
    return { error: e.message, sessions: [] };
  }
}

// ---- presets ----------------------------------------------------------------

let bundle;

if (mode === "standup") {
  const d = resolveDate(dateToken);
  const followups = readVaultFile("followups.md");
  bundle = {
    mode,
    vault: resolveVault(),
    ...d,
    standup: standupFile(d.date),
    reviews: readVaultFile(`reviews/${d.date}.md`),
    followups: {
      ...followups,
      completedForDate: completedForDate(followups.content, d.date),
    },
    wikilinkTargets: wikilinkTargets(),
    sessions: runSessions(d.date),
  };
} else if (mode === "briefing") {
  const d = resolveDate("today");
  const followups = readVaultFile("followups.md");
  bundle = {
    mode,
    vault: resolveVault(),
    today: d.today,
    yesterday: d.yesterday,
    weekdayToday: d.weekday,
    yesterdayStandup: standupFile(d.yesterday),
    todayStandup: standupFile(d.today),
    followups: {
      ...followups,
      unchecked: uncheckedFollowups(followups.content),
    },
    activeInvestigations: activeInvestigations(),
    standupFiles: listFolder("standup"),
  };
} else if (mode === "add") {
  const d = resolveDate(dateToken);
  bundle = {
    mode,
    vault: resolveVault(),
    ...d,
    standup: standupFile(d.date),
    wikilinkTargets: wikilinkTargets(),
  };
} else if (mode === "compact") {
  const d = resolveDate(dateToken, { defaultYesterday: true });
  bundle = {
    mode,
    vault: resolveVault(),
    ...d,
    standup: standupFile(d.date),
  };
} else {
  console.error(`gather.js: unknown --for "${mode}"`);
  process.exit(2);
}

console.log(JSON.stringify(bundle, null, 2));
