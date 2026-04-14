#!/usr/bin/env node

/**
 * Extracts Claude Code skill usage stats from history.jsonl.
 *
 * Usage:
 *   node extract-usage.js [--since YYYY-MM-DD]
 *
 * Without --since: scans entire history.
 * With --since: only scans entries after that date.
 *
 * Output: JSON object mapping skill names to usage data:
 *   {
 *     "git:commit": { "count": 12, "lastUsed": "2026-04-14", "projects": ["dotfiles", "Viper"], "sessions": 8 },
 *     ...
 *   }
 *
 * Only counts user-defined skills (starts with "/" and contains ":" or matches known command patterns).
 * Excludes built-in CLI commands: /help, /clear, /model, /cost, /context, /resume, /compact,
 * /statusline, /fast, /rewind, /bug, /doctor, /exit, /quit, /config, /memory, /permissions,
 * /terminal-setup, /mcp, /hooks, /vim, /init, /listen, /review, /diff, /pr-comments, /login, /logout
 */

import fs from "node:fs";
import path from "node:path";
import { homedir } from "node:os";
import readline from "node:readline";

const HISTORY_FILE = path.join(homedir(), ".claude", "history.jsonl");

const BUILTIN_COMMANDS = new Set([
  "help", "clear", "model", "cost", "context", "resume", "compact",
  "statusline", "fast", "rewind", "bug", "doctor", "exit", "quit",
  "config", "memory", "permissions", "terminal-setup", "mcp", "hooks",
  "vim", "init", "listen", "review", "diff", "pr-comments", "login",
  "logout", "add-dir", "release-notes", "ide", "loop",
  // Common single-word builtins that overlap with skill-like patterns
  "usage", "status", "stats", "theme", "rate-limit-options", "plugin",
  "chrome", "open-repo", "effort", "obs", "btw", "excalidrawx",
]);

// Renamed skills — map old names to current canonical names
const RENAMES = {
  "git-commit": "git:commit",
  "git-pr": "git:pr",
  "standup-notes": "obsidian:standup",
  "obsidian-standup": "obsidian:standup",
  "obsidian-followup": "obsidian:followup",
  "obsidian-investigate": "obsidian:investigate",
  "obsidian-briefing": "obsidian:briefing",
  "obsidian-pr-notes": "obsidian:pr-notes",
  "research-orderings": "research:orderings",
  "spec-developer": "spec:developer",
  "spec-implement": "spec:implement",
  "spec-audit": "spec:audit",
  "spec-advisor": "spec:advisor",
  "mcp-restart": "mcp:restart",
};

// Bare namespace invocations (e.g., "/factory" without subcommand) — noise
const NAMESPACE_ONLY = new Set([
  "factory", "obsidian", "git", "gsd", "ffmpeg", "spec", "dev",
  "research", "mcp", "notebooklm", "caveman", "linting",
]);

// Parse args
const args = process.argv.slice(2);
let sinceDate = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--since" && args[i + 1]) {
    sinceDate = args[++i];
  }
}

const sinceTimestamp = sinceDate
  ? new Date(`${sinceDate}T00:00:00`).getTime()
  : 0;

async function main() {
  if (!fs.existsSync(HISTORY_FILE)) {
    console.log(JSON.stringify({}));
    process.exit(0);
  }

  const usage = {};

  const stream = fs.createReadStream(HISTORY_FILE, { encoding: "utf8" });
  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });

  for await (const line of rl) {
    if (!line.trim()) continue;

    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    }

    const { display, timestamp, project, sessionId } = entry;
    if (!display || !timestamp) continue;

    // Skip entries before the since date
    if (timestamp < sinceTimestamp) continue;

    // Must start with /
    const trimmed = display.trim();
    if (!trimmed.startsWith("/")) continue;

    // Extract skill name (first token after /)
    const skillName = trimmed.slice(1).split(/\s+/)[0].toLowerCase();
    if (!skillName) continue;

    // Skip built-in commands
    if (BUILTIN_COMMANDS.has(skillName)) continue;

    // Skip file paths pasted with leading / (e.g., /users/derek/downloads/...)
    if (skillName.includes("/")) continue;

    // Skip single-char "commands" (typos) and bare trailing colons (e.g., "viper:")
    if (skillName.length <= 1 || skillName.endsWith(":")) continue;

    // Skip bare namespace invocations (e.g., "/factory" without subcommand)
    if (NAMESPACE_ONLY.has(skillName)) continue;

    // Resolve renamed skills to canonical name
    const canonicalName = RENAMES[skillName] || skillName;

    // Extract project short name from path
    const projectName = project
      ? path.basename(project)
      : "unknown";

    const dateStr = new Date(timestamp).toISOString().slice(0, 10);

    if (!usage[canonicalName]) {
      usage[canonicalName] = {
        count: 0,
        lastUsed: dateStr,
        firstUsed: dateStr,
        projects: new Set(),
        sessions: new Set(),
      };
    }

    const u = usage[canonicalName];
    u.count++;
    if (dateStr > u.lastUsed) u.lastUsed = dateStr;
    if (dateStr < u.firstUsed) u.firstUsed = dateStr;
    u.projects.add(projectName);
    if (sessionId) u.sessions.add(sessionId);
  }

  // Convert Sets to arrays/counts for JSON output
  const output = {};
  for (const [name, data] of Object.entries(usage)) {
    output[name] = {
      count: data.count,
      lastUsed: data.lastUsed,
      firstUsed: data.firstUsed,
      projects: [...data.projects].sort(),
      sessions: data.sessions.size,
    };
  }

  console.log(JSON.stringify(output, null, 2));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
