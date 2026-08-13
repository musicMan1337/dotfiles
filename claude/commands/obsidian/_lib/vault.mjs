#!/usr/bin/env node

/**
 * Shared deterministic helpers for the obsidian:* skills.
 *
 * The vault is a plain directory, so every read is done with fs directly,
 * NOT through the `obsidian` app binary. This removes the fragile parts the
 * model used to do by hand: resolving the vault path, computing dates, and
 * issuing `obsidian read` / `obsidian files` calls it could typo or fumble.
 *
 * Writes go through _lib/write.mjs, also straight to the filesystem. There is
 * no `obsidian` CLI to route them through: the `obsidian` on PATH is the app
 * binary, and calling it with `create path=... content=...` just opens the app
 * and drops a stray `Untitled N.md` in the vault root. Obsidian indexes
 * filesystem changes on its own, so a direct write is all that is needed.
 */

import fs from "node:fs";
import path from "node:path";
import { homedir } from "node:os";

const HARDCODED_VAULT = "/Users/derek/eBacon/obsidian/eBacon";
const OBSIDIAN_CONFIG = path.join(
  homedir(),
  "Library",
  "Application Support",
  "Obsidian",
  "obsidian.json"
);

/**
 * Resolve the vault root from Obsidian's own config (the `open:true` vault),
 * so this survives a vault move. Falls back to the known path.
 */
export function resolveVault() {
  try {
    const cfg = JSON.parse(fs.readFileSync(OBSIDIAN_CONFIG, "utf8"));
    const vaults = Object.values(cfg.vaults || {});
    const open = vaults.find((v) => v.open) || vaults[0];
    if (open?.path && fs.existsSync(open.path)) return open.path;
  } catch {}
  return HARDCODED_VAULT;
}

const VAULT = resolveVault();

export function vaultPath(rel) {
  return path.join(VAULT, rel);
}

/** Read a vault file by relative path. Never throws on missing — returns exists:false. */
export function readVaultFile(rel) {
  const abs = vaultPath(rel);
  if (!fs.existsSync(abs)) return { path: rel, exists: false, content: null };
  try {
    return { path: rel, exists: true, content: fs.readFileSync(abs, "utf8") };
  } catch (e) {
    return { path: rel, exists: false, content: null, error: e.message };
  }
}

/** List `.md` basenames (no extension) directly under a vault folder. [] if absent. */
export function listFolder(rel) {
  const abs = vaultPath(rel);
  if (!fs.existsSync(abs)) return [];
  try {
    return fs
      .readdirSync(abs)
      .filter((f) => f.endsWith(".md"))
      .map((f) => f.slice(0, -3))
      .sort();
  } catch {
    return [];
  }
}

// ---- Dates ------------------------------------------------------------------

function fmt(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function weekdayName(d) {
  return d.toLocaleDateString("en-US", { weekday: "long" });
}

function shift(base, days) {
  const d = new Date(base.getFullYear(), base.getMonth(), base.getDate());
  d.setDate(d.getDate() + days);
  return d;
}

/** Prior workday with Mon->Fri rollback (Mon: -3, Sun: -2, else: -1). */
function priorWorkday(base) {
  const dow = base.getDay(); // 0=Sun .. 6=Sat
  if (dow === 1) return shift(base, -3); // Monday -> Friday
  if (dow === 0) return shift(base, -2); // Sunday -> Friday
  return shift(base, -1);
}

const WEEKDAYS = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];

/** Most recent past date (1..7 days back) matching a weekday name. */
function lastWeekday(base, name) {
  const target = WEEKDAYS.indexOf(name.toLowerCase());
  if (target < 0) return null;
  for (let i = 1; i <= 7; i++) {
    const d = shift(base, -i);
    if (d.getDay() === target) return d;
  }
  return null;
}

/**
 * Resolve a date token to YYYY-MM-DD.
 *   undefined / "today"        -> today (unless defaultYesterday)
 *   "yesterday"                -> prior workday
 *   "monday".."friday" etc     -> most recent past matching weekday
 *   "2026-05-28"               -> that exact date
 * Returns { date, weekday, today, yesterday }.
 */
export function resolveDate(token, { defaultYesterday = false } = {}) {
  const now = new Date();
  const todayStr = fmt(now);
  const yesterdayStr = fmt(priorWorkday(now));

  let target = now;
  const t = (token || "").trim().toLowerCase();

  if (/^\d{4}-\d{2}-\d{2}$/.test(token || "")) {
    target = new Date(`${token}T12:00:00`);
  } else if (t === "yesterday") {
    target = priorWorkday(now);
  } else if (WEEKDAYS.includes(t)) {
    target = lastWeekday(now, t) || now;
  } else if (t === "today") {
    target = now;
  } else if (!t && defaultYesterday) {
    target = priorWorkday(now);
  }

  return {
    date: fmt(target),
    weekday: weekdayName(target),
    today: todayStr,
    yesterday: yesterdayStr,
  };
}

// ---- Parsing helpers --------------------------------------------------------

const SECTION_HEADERS = [
  "## Today",
  "## Completed",
  "## Yesterday",
  "## Open Follow-ups",
  "## Active Investigations",
  "## PRs Awaiting Your Review",
  "## Your Open PRs",
];

/** A finalized standup is a flat numbered list with none of the briefing `##` sections. */
export function isFinalizedStandup(content) {
  if (!content) return false;
  return !SECTION_HEADERS.some((h) => content.includes(h));
}

/** Extract the `## Completed` block (locked items) from a standup file, or null. */
export function extractCompletedBlock(content) {
  if (!content) return null;
  const lines = content.split("\n");
  const start = lines.findIndex((l) => l.trim() === "## Completed");
  if (start < 0) return null;
  const body = [];
  for (let i = start + 1; i < lines.length; i++) {
    if (/^##\s/.test(lines[i]) || lines[i].trim() === "---") break;
    body.push(lines[i]);
  }
  return body.join("\n").trim() || null;
}

/** Unchecked follow-up lines (`- [ ]`). */
export function uncheckedFollowups(content) {
  if (!content) return [];
  return content.split("\n").filter((l) => /^\s*-\s*\[ \]/.test(l));
}

/**
 * Follow-ups completed on a specific date. Matches a `**Completed YYYY-MM-DD:**`
 * sub-bullet and pairs it with the nearest preceding `- [x]`/`- [ ]` item line.
 * Returns [{ item, note }].
 */
export function completedForDate(content, date) {
  if (!content) return [];
  const lines = content.split("\n");
  const out = [];
  let lastItem = null;
  const tag = `**Completed ${date}:**`;
  for (const line of lines) {
    if (/^\s*-\s*\[[ x]\]/.test(line)) lastItem = line.trim();
    if (line.includes(tag)) {
      out.push({ item: lastItem, note: line.trim() });
    }
  }
  return out;
}

/** Active investigations: files whose content contains `Status: Active`. */
export function activeInvestigations() {
  const out = [];
  for (const slug of listFolder("investigations")) {
    const { content } = readVaultFile(`investigations/${slug}.md`);
    if (content && content.includes("Status: Active")) {
      out.push({ slug, content });
    }
  }
  return out;
}
