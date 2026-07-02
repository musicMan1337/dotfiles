#!/usr/bin/env node
// Subagent Gate: PreToolUse hook (HARD block) + per-session concurrency cap.
//
// Gate 1 (model pinning): forces every subagent spawn to NAME a model-pinned
// agent instead of falling back to types that silently inherit the main
// session model (e.g. Opus) and caused the Opus cost blowout.
// Policy: DENYLIST. Blocked are the generic catch-alls ("general-purpose" /
// "claude"), an empty/missing type (which defaults to a catch-all), AND the
// unpinned built-ins "Explore" and "Plan": their agent definitions declare no
// `model:`, so they inherit the session model just like the catch-alls (same
// cost risk, and no way to know the resolved tier). Read/grep sweeps route to
// "reader" (haiku) instead; planning routes to "planner" (opus).
//
// Gate 2 (concurrency cap): caps concurrent subagents per session at
// SUBAGENT_CAP (default 4). Sophos CryptoGuard flags the file-I/O burst of
// wide agent fan-outs (concurrent transcript JSONL appends + scratch writes)
// as ransomware-like; capping the fan-out kills the burst signature.
// Per-session only by design: parallel sessions each get their own cap.
//
// Slot accounting (this script is registered for three hook events):
//   PreToolUse (Agent|Task)  -> prune stale slots, deny if >= cap, else claim
//   SubagentStop             -> release the oldest slot for the session
//   SessionEnd               -> delete the session's slot file
// Slots also self-expire after SLOT_TTL_MS: SubagentStop delivery is not
// guaranteed (docs don't pin down its schema/timing), so a missed stop event
// degrades to a temporary throttle, never a deadlock. Concurrent PreToolUse
// firings can race the read-modify-write and briefly over-admit by one; the
// cap is a burst heuristic, not a scheduler, so that's acceptable.
// NOTE: Workflow-tool agent() calls do NOT pass through these hooks; Workflow
// scripts must self-limit (see CLAUDE.md Subagent Strategy).
//
// On a denied spawn, Claude Code feeds permissionDecisionReason back to the
// model, which retries with a named agent / smaller fan-out. Deny only: no
// input rewriting.
//
// Escape valve: set SUBAGENT_GATE_OFF=1 in the environment to disable both gates.

const fs = require('fs');
const path = require('path');
const os = require('os');

const DENIED = new Set(['general-purpose', 'claude', 'Explore', 'Plan']);
const CAP = Math.max(1, parseInt(process.env.SUBAGENT_CAP || '4', 10) || 4);
const SLOT_TTL_MS = 10 * 60 * 1000;
const STATE_DIR = path.join(os.homedir(), '.claude', 'tmp', 'subagent-slots');

function slotFile(sessionId) {
  // session_id is harness-generated, but sanitize anyway before using as a filename.
  return path.join(STATE_DIR, `${String(sessionId).replace(/[^A-Za-z0-9_-]/g, '_')}.json`);
}

function readSlots(sessionId) {
  try {
    const arr = JSON.parse(fs.readFileSync(slotFile(sessionId), 'utf8'));
    if (!Array.isArray(arr)) return [];
    const now = Date.now();
    return arr.filter((t) => typeof t === 'number' && now - t < SLOT_TTL_MS);
  } catch (e) {
    return [];
  }
}

function writeSlots(sessionId, slots) {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(slotFile(sessionId), JSON.stringify(slots));
}

function deny(reason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'deny',
        permissionDecisionReason: reason,
      },
    })
  );
}

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => (input += chunk));
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    if (process.env.SUBAGENT_GATE_OFF === '1') process.exit(0);

    const data = JSON.parse(input);
    const event = data.hook_event_name;
    const sessionId = data.session_id;

    if (event === 'SubagentStop') {
      if (sessionId) {
        const slots = readSlots(sessionId);
        slots.sort((a, b) => a - b).shift(); // release oldest claim
        writeSlots(sessionId, slots);
      }
      process.exit(0);
    }

    if (event === 'SessionEnd') {
      if (sessionId) {
        try {
          fs.unlinkSync(slotFile(sessionId));
        } catch (e) {}
      }
      process.exit(0);
    }

    // PreToolUse from here down.
    const toolName = data.tool_name;
    if (toolName !== 'Task' && toolName !== 'Agent') process.exit(0);

    const ti = data.tool_input || {};
    const requested = ti.subagent_type || ti.agentType || ti.subagentType || '';

    // Gate 1: block the catch-alls and the no-type-given case (which defaults to one).
    if (!requested || DENIED.has(requested)) {
      deny(
        `Subagent gate: "${requested || '(no type given)'}" inherits the session ` +
          `model (expensive) or has no pinned model. Pick a model-pinned agent and retry:\n` +
          `  • read/grep/lookup  → "reader" (haiku)\n` +
          `  • read + classify   → "classifier" (sonnet)\n` +
          `  • heavy synthesis   → "synthesizer" (opus, only when truly needed)\n` +
          `  • planning          → "planner" (opus)\n` +
          `  • a purpose-built / plugin agent for its domain\n` +
          `The session must choose a pinned agent explicitly: no catch-all, no Explore/Plan.`
      );
      process.exit(0);
    }

    // Gate 2: per-session concurrency cap.
    if (sessionId) {
      const slots = readSlots(sessionId);
      if (slots.length >= CAP) {
        deny(
          `Subagent cap: ${CAP} concurrent subagents already running in this session ` +
            `(Sophos CryptoGuard flags wider file-I/O fan-outs as ransomware-like). Do NOT retry immediately. Instead:\n` +
            `  1. Wait for a running subagent to finish, then retry (a slot frees on each SubagentStop; stale slots expire after ${SLOT_TTL_MS / 60000} min).\n` +
            `  2. Better: restructure: ONE aggregate agent given the full file list (single rg/jq pass) instead of many small sweepers.\n` +
            `  3. For repeated analysis over large logs, index once (sqlite / rag MCP), then query the index.\n` +
            `Agents must return results in their final message, never via scratchpad temp files.`
        );
        process.exit(0);
      }
      slots.push(Date.now());
      writeSlots(sessionId, slots);
    }

    process.exit(0);
  } catch (e) {
    // Never hard-fail a spawn on a hook error.
    process.exit(0);
  }
});
