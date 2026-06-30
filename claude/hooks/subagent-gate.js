#!/usr/bin/env node
// Subagent Gate — PreToolUse hook (HARD block)
// Forces every subagent spawn to NAME a specific agent instead of falling back
// to the generic catch-alls ("general-purpose" / "claude"), which silently
// inherit the main session model (e.g. Opus) and caused the Opus cost blowout.
//
// Policy: DENYLIST. Only the two catch-alls (and an empty/missing type, which
// defaults to a catch-all) are blocked. Every explicitly-named agent passes —
// built-ins (Explore, Plan, claude-code-guide, statusline-setup), namespaced
// plugin agents, and any defined .md agent. Named agents either carry a pinned
// `model:` (reader=haiku, classifier=sonnet, synthesizer=opus) or are a
// deliberate choice (Plan may inherit a stronger model on purpose).
//
// On a denied spawn, Claude Code feeds permissionDecisionReason back to the
// model, which retries with a named agent. Deny only — no input rewriting.
//
// Escape valve: set SUBAGENT_GATE_OFF=1 in the environment to disable.

const DENIED = new Set(['general-purpose', 'claude']);

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => (input += chunk));
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    if (process.env.SUBAGENT_GATE_OFF === '1') process.exit(0);

    const data = JSON.parse(input);
    const toolName = data.tool_name;
    if (toolName !== 'Task' && toolName !== 'Agent') process.exit(0);

    const ti = data.tool_input || {};
    const requested = ti.subagent_type || ti.agentType || ti.subagentType || '';

    // Block only the catch-alls and the no-type-given case (which defaults to one).
    if (!requested || DENIED.has(requested)) {
      const reason =
        `Subagent gate: "${requested || '(no type given)'}" is a catch-all that ` +
        `inherits the session model (expensive). Pick a SPECIFIC agent and retry:\n` +
        `  • read/grep/lookup  → "Explore" (haiku) or "reader" (haiku)\n` +
        `  • read + classify   → "classifier" (sonnet)\n` +
        `  • heavy synthesis   → "synthesizer" (opus, only when truly needed)\n` +
        `  • planning          → "Plan"\n` +
        `  • a purpose-built / plugin agent for its domain\n` +
        `The session must choose an agent explicitly — no generic catch-all.`;
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: 'PreToolUse',
          permissionDecision: 'deny',
          permissionDecisionReason: reason,
        },
      }));
      process.exit(0);
    }

    process.exit(0);
  } catch (e) {
    // Never hard-fail a spawn on a hook error.
    process.exit(0);
  }
});
