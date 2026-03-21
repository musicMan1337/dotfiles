#!/usr/bin/env node

/**
 * Extracts Claude Code session activity for a given date and time window.
 *
 * Usage:
 *   node extract-sessions.js [YYYY-MM-DD] [--start HH] [--end HH]
 *
 * Defaults: today, 06:00-17:00 (6am-5pm)
 *
 * Output: JSON array of session summaries, each containing:
 *   - project: project path
 *   - sessionId: UUID
 *   - prompts: user prompts (strings)
 *   - tools: tool usage summary (tool name -> count)
 *   - files: files touched (edited/written/read)
 *   - commits: git commit messages found in Bash output
 *   - branches: git branches active during session
 *   - textSummaries: assistant text responses (truncated)
 */

import fs from "node:fs";
import path from "node:path";
import { homedir } from "node:os";
import readline from "node:readline";

const CLAUDE_DIR = path.join(homedir(), ".claude");
const HISTORY_FILE = path.join(CLAUDE_DIR, "history.jsonl");
const PROJECTS_DIR = path.join(CLAUDE_DIR, "projects");

// Parse args
const args = process.argv.slice(2);
let targetDate = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
let startHour = 6;
let endHour = 17;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--start" && args[i + 1]) {
    startHour = parseInt(args[++i]);
  } else if (args[i] === "--end" && args[i + 1]) {
    endHour = parseInt(args[++i]);
  } else if (/^\d{4}-\d{2}-\d{2}$/.test(args[i])) {
    targetDate = args[i];
  }
}

// Build time window in local time
const windowStart = new Date(`${targetDate}T${String(startHour).padStart(2, "0")}:00:00`);
const windowEnd = new Date(`${targetDate}T${String(endHour).padStart(2, "0")}:00:00`);

function inWindow(timestamp) {
  let d;
  if (typeof timestamp === "number") {
    d = new Date(timestamp);
  } else if (typeof timestamp === "string") {
    d = new Date(timestamp);
  } else {
    return false;
  }
  return d >= windowStart && d <= windowEnd;
}

// Step 1: Find sessions active on target date from history.jsonl
async function getSessionsForDate() {
  const sessions = new Map(); // sessionId -> { project, display, timestamp }

  if (!fs.existsSync(HISTORY_FILE)) return sessions;

  const stream = fs.createReadStream(HISTORY_FILE);
  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });

  for await (const line of rl) {
    if (!line.trim()) continue;
    try {
      const entry = JSON.parse(line);
      if (inWindow(entry.timestamp)) {
        sessions.set(entry.sessionId, {
          project: entry.project,
          display: entry.display,
          timestamp: entry.timestamp,
        });
      }
    } catch {}
  }

  return sessions;
}

// Step 2: Find session JSONL file across all project directories
function findSessionFile(sessionId) {
  if (!fs.existsSync(PROJECTS_DIR)) return null;

  const projectDirs = fs.readdirSync(PROJECTS_DIR);
  for (const dir of projectDirs) {
    const candidate = path.join(PROJECTS_DIR, dir, `${sessionId}.jsonl`);
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

// Step 3: Parse a session file for activity within the time window
async function parseSession(filePath, sessionMeta) {
  const result = {
    project: sessionMeta.project,
    sessionId: path.basename(filePath, ".jsonl"),
    prompts: [],
    tools: {},
    filesEdited: new Set(),
    filesCreated: new Set(),
    commits: [],
    branches: new Set(),
    textSnippets: [],
  };

  const stream = fs.createReadStream(filePath);
  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });

  for await (const line of rl) {
    if (!line.trim()) continue;
    try {
      const entry = JSON.parse(line);

      // Only process entries within our time window
      if (!entry.timestamp || !inWindow(entry.timestamp)) continue;

      if (entry.gitBranch) result.branches.add(entry.gitBranch);

      if (entry.type === "user" && entry.message?.content) {
        const prompt = typeof entry.message.content === "string"
          ? entry.message.content
          : JSON.stringify(entry.message.content);

        // Skip system/hook messages, keep real user prompts
        if (prompt.length > 0 && prompt.length < 2000 && entry.userType === "external") {
          result.prompts.push(prompt.slice(0, 300));
        }
      }

      if (entry.type === "assistant" && Array.isArray(entry.message?.content)) {
        for (const block of entry.message.content) {
          if (block.type === "text" && block.text) {
            // Capture short text responses as context clues
            if (block.text.length > 20 && block.text.length < 500) {
              result.textSnippets.push(block.text.slice(0, 200));
            }
          }

          if (block.type === "tool_use") {
            const tool = block.name;
            result.tools[tool] = (result.tools[tool] || 0) + 1;

            // Track files
            if (tool === "Edit" || tool === "Write") {
              const fp = block.input?.file_path;
              if (fp) {
                if (tool === "Write") result.filesCreated.add(fp);
                else result.filesEdited.add(fp);
              }
            }

            // Look for git commits in Bash calls
            if (tool === "Bash" && block.input?.command) {
              const cmd = block.input.command;
              if (cmd.includes("git commit")) {
                // Extract commit message if present
                const msgMatch = cmd.match(/(?:-m\s+["']|<<['"]?EOF\n?)([\s\S]*?)(?:["']|EOF)/);
                if (msgMatch) result.commits.push(msgMatch[1].trim().split("\n")[0]);
              }
            }
          }
        }
      }
    } catch {}
  }

  // Convert sets to arrays for JSON serialization
  result.filesEdited = [...result.filesEdited];
  result.filesCreated = [...result.filesCreated];
  result.branches = [...result.branches];

  // Cap arrays to avoid bloat
  result.textSnippets = result.textSnippets.slice(0, 15);
  result.prompts = result.prompts.slice(0, 30);

  return result;
}

// Main
async function main() {
  const sessions = await getSessionsForDate();

  if (sessions.size === 0) {
    console.log(JSON.stringify({ date: targetDate, window: `${startHour}:00-${endHour}:00`, sessions: [] }));
    return;
  }

  const results = [];

  for (const [sessionId, meta] of sessions) {
    const filePath = findSessionFile(sessionId);
    if (!filePath) continue;

    const parsed = await parseSession(filePath, meta);
    // Only include sessions with actual activity
    if (parsed.prompts.length > 0 || Object.keys(parsed.tools).length > 0) {
      results.push(parsed);
    }
  }

  console.log(JSON.stringify({ date: targetDate, window: `${startHour}:00-${endHour}:00`, sessions: results }, null, 2));
}

main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
