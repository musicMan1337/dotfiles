---
name: setup:sub-agent-config
model: sonnet
description: Set up or verify this machine's Claude Code subagent cost-control config — the PreToolUse gate hook that blocks catch-all agent spawns, the model-pinned named agents (reader/classifier/synthesizer/committer), and the rules that keep subagents off Opus. Idempotent: detects current state, reports gaps, fixes what's missing. Triggers on, setup subagent config, sub-agent config, subagent cost control, subagent gate, fix subagent models, configure subagents, subagent model setup, agent gate hook, /setup:sub-agent-config.
allowed-tools: Agent, Bash, Read, Write, Edit, Glob, Grep, Skill
---

Goal: ensure this machine's Claude Code environment controls subagent token cost. Two levers are at play, and this skill wires both:

1. **Model tier** — subagents must not silently inherit an expensive session model (e.g. Opus). The default catch-all agents (`general-purpose`, `claude`) inherit the session model, so a fan-out of hundreds spawns hundreds of Opus agents. The fix forces every spawn to name a model-pinned agent.
2. **Context prefix** — every fresh subagent re-instantiates the full system prompt + all tool schemas (tens of thousands of tokens, up to ~160k in a heavily-loaded session). Pinning each agent to a minimal `tools:` allowlist shrinks that per-spawn tax.

This is a personal-dotfiles config; all paths are `~/dotfiles/claude/...` symlinked into `~/.claude/...`.

## The architecture (what "correct" looks like)

**A. A PreToolUse gate hook** (`claude/hooks/subagent-gate.js`) on the `Agent|Task` matcher. Policy is a DENYLIST: it blocks only the catch-all types (`general-purpose`, `claude`) and the no-type-given case (which defaults to a catch-all). Every explicitly-named agent passes — built-ins (`Explore`, `Plan`, `claude-code-guide`, `statusline-setup`), namespaced plugin agents, and any defined `.md` agent. On a denied spawn it returns `permissionDecision: "deny"` with a reason, and Claude Code feeds the reason back so the model retries with a named agent. Deny only, no input rewriting (which is unconfirmed for the Agent/Task tool). Escape valve: `SUBAGENT_GATE_OFF=1`.

**B. Model-pinned named agents** in `claude/agents/` (symlinked to `~/.claude/agents/`):

| agent | model | tools | use |
|---|---|---|---|
| `reader` | haiku | Read, Grep, Glob, Bash | pure search/lookup/read, no analysis |
| `classifier` | sonnet | Read, Grep, Glob, Bash | read + light judgment (bucketing, triage, migration mapping) |
| `synthesizer` | opus | Read, Grep, Glob, Bash, WebFetch | genuine heavy synthesis, used sparingly |
| `committer` | haiku | Read, Bash | the one agent allowed to run mutating git for `/git:commit` |

**C. NO `CLAUDE_CODE_SUBAGENT_MODEL` env var** in `claude/settings.json`. That env var is the highest-precedence model override — it beats per-call `model`, agent frontmatter, AND `Explore`'s hardcoded haiku, pinning ALL subagents to one model. That defeats per-agent precision (every agent forced to the same tier). Use the gate + per-agent frontmatter instead, not the env var.

**D. `/git:commit` points at the `committer` agent.** The commit skill spawns `subagent_type: "committer"` (not a generic haiku agent, which the gate now blocks) and self-validates Conventional Commits format (no external commit hook needed).

## Setup / repair (idempotent — run each check, fix only gaps)

### Step 1 — Audit current state

Run a Haiku-or-inline audit (use the `reader` agent if it exists, else inline since the gate may block catch-alls):

```bash
echo "=== env var (must be UNSET) ==="; echo "${CLAUDE_CODE_SUBAGENT_MODEL:-<unset>}"
grep -c "CLAUDE_CODE_SUBAGENT_MODEL" ~/dotfiles/claude/settings.json
echo "=== gate hook present? ==="; ls -l ~/.claude/hooks/subagent-gate.js 2>/dev/null
grep -c "subagent-gate.js" ~/dotfiles/claude/settings.json
echo "=== named agents present? ==="; ls ~/.claude/agents/{reader,classifier,synthesizer,committer}.md 2>/dev/null
echo "=== commit skill wired to committer? ==="; grep -c 'subagent_type: "committer"' ~/dotfiles/claude/commands/git/commit.md
```

Report which of A/B/C/D are already satisfied. Only act on gaps.

### Step 2 — Gate hook

If `claude/hooks/subagent-gate.js` is missing, create it (denylist policy above). If its `settings.json` entry is missing, add to `hooks.PreToolUse` a block with `"matcher": "Agent|Task"` invoking it via the repo's node path. Match the existing hook-invocation style in `settings.json`.

### Step 3 — Named agents

For each of `reader`, `classifier`, `synthesizer`, `committer` missing from `claude/agents/`, create it with the model + tools from the table above and a terse system prompt stating its lane (read-only for reader/classifier; mutation-permitted only for committer). Ensure the agents symlink loop exists in `_mac/symlinks.sh` (mirrors the hooks loop), then symlink any new agent into `~/.claude/agents/`.

### Step 4 — Remove the env var

If `CLAUDE_CODE_SUBAGENT_MODEL` is in `settings.json` `env`, remove it. Note: removing it from the file does NOT unset it in an already-running session (env is injected at start) — a restart is required for the change to take effect.

### Step 5 — Wire the commit skill

If `claude/commands/git/commit.md` still spawns a generic haiku agent, change it to `subagent_type: "committer"` and confirm it carries the Conventional Commits self-validation step.

### Step 6 — Verify

After a **restart** (required for new agents to register and for env-var removal to take effect), confirm:

```bash
# gate blocks catch-alls (spawn general-purpose → expect a deny)
# named agents run on their pinned model (spawn reader → expect haiku)
```

Spawn a trivial `reader` agent, then read its model from the transcript — it must be `claude-haiku-4-5`. Spawn `general-purpose` — it must be denied by the gate.

## Reference facts (why it's built this way)

- **Model resolution precedence** (Claude Code docs): `CLAUDE_CODE_SUBAGENT_MODEL` env var → per-invocation `model` param → agent frontmatter `model:` → session model. The env var wins over everything; frontmatter beats session inheritance only when the env var is unset.
- **Built-ins**: `general-purpose`/`claude`/`Plan` inherit the session model; `Explore` is hardcoded haiku; `claude-code-guide`/`statusline-setup` have baked-in small/fast tiers. `Plan` is allowed by the gate on purpose (planning may warrant a stronger inherited model).

## Gotchas

- **The env var is a hard override, not a floor.** If set, it forces every subagent (even `Explore`, even explicit per-call overrides) to one model. Keep it unset; rely on the gate + frontmatter.
- **Agent registration lags file creation.** A newly created `.md` agent is not spawnable until the registry reloads (often needs a restart). Until then, spawning it errors "agent type not found."
- **Workflow `agent()` spawns bypass the gate.** The PreToolUse hook intercepts the Agent/Task *tool*, not workflow-runtime spawns. In Workflow scripts, pin `model`/`agentType` per `agent()` call yourself — the gate will not catch a `general-purpose` spawn inside a workflow.
- **`/git:commit` depends on the `committer` agent.** If `committer` is missing or unregistered, the commit skill's spawn is blocked by the gate. Keep `committer` present; on a fresh machine, commit once via an already-registered named agent until `committer` registers.
- **Don't reintroduce `CLAUDE_CODE_SUBAGENT_MODEL` as a "backstop"** alongside the agents — it overrides their frontmatter and collapses all four agents to one tier.
