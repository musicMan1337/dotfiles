---
model: haiku
description: Audit Claude Code session for context bloat and wasted tokens. Triggers on: audit usage, context bloat, token usage
---

# Usage & Context Audit

Analyze the current Claude Code environment for invisible context bloat and misconfigured settings that waste tokens. Report findings with a score and actionable fixes.

## What to Check

Run all checks in parallel where possible. For each finding, classify severity:
- **Critical** — actively wasting significant tokens every message
- **Warning** — suboptimal but not urgent
- **Good** — correctly configured

### 1. MCP Servers (biggest token sink)

Every connected MCP server loads all tool definitions into context on **every message**, not just when called. One server can add ~18,000 tokens.

**Check:** Run `/mcp` or inspect the active MCP connections. Count how many are connected and estimate their token overhead. Flag any that:
- Have 10+ tool definitions (heavy context cost)
- Have a CLI alternative available (CLI only costs tokens when actually called — ~40% savings)
- Are unlikely to be used in this session's project context

**Fix guidance:** Disconnect unused servers at session start. Replace MCP servers with CLI equivalents where available (e.g., Playwright MCP → Playwright plugin/CLI, Firecrawl MCP → Firecrawl CLI).

### 2. CLAUDE.md Files

These load into context at the start of every session and compound on every API call.

**Check:** Read all active CLAUDE.md files (global `~/.claude/CLAUDE.md`, project root `CLAUDE.md`, any `.claude/rules/*.md`). For each rule, apply these five filters:

1. **Default behavior?** — Would Claude already do this without being told?
2. **Contradicts another rule?** — Two rules that can't both be satisfied
3. **Repeats existing coverage?** — Same instruction said differently elsewhere
4. **Band-aid for a one-time bad output?** — Overly specific fix that doesn't generalize
5. **Too vague to be actionable?** — "be natural", "use good tone", "be more helpful"

Also check for **progressive disclosure violations**: detailed domain-specific instructions (API conventions, testing guidelines, deployment rules) that belong in reference files with a one-line pointer, not inline in the core CLAUDE.md. The core file should only contain rules that apply to every session in that repo.

**Fix guidance:** Cut rules that fail any filter. Move domain-specific blocks to reference `.md` files and replace with one-line pointers like: `For API conventions, read api-standards.md`.

### 3. Skills Audit

Every installed skill's metadata loads into context so Claude can decide whether to trigger it.

**Check:** List all skills in `~/.claude/commands/` and any project `.claude/commands/`. Flag skills that:
- Are over 300 lines of instructions (verbose — competing for attention)
- Haven't been used in weeks (dead weight)
- Overlap significantly with another skill (redundant routing)
- Have vague descriptions that cause false triggers

**Fix guidance:** Remove or consolidate low-value skills. Trim verbose skills — past a certain length, Claude starts ignoring rules as too much competes for attention.

### 4. Settings.json

**Check** `~/.claude/settings.json` for these specific settings:

| Setting | Recommended | Why |
|---------|-------------|-----|
| `autoCompactThreshold` | 75 | Default (~83%) lets quality degrade before compaction triggers |
| `terminalOutputLimit` | 150000 | Default (30-50k) causes silent truncation and costly retries |
| Deny rules for `node_modules`, `dist`, `build`, `.next`, lock files | Present | Prevents Claude from reading build artifacts and wasting context |

Flag any that are missing or misconfigured.

### 5. Session Hygiene Quick-Check

Report the current session state:
- How many messages deep is this session? (deeper = more compounding cost)
- Is this session mixing unrelated tasks? (should `/clear` between topics)
- Are there large tool results sitting in context from earlier? (bloating every future message)

## Output Format

Present findings as a scorecard:

```
## Context Audit Results

**Score: X/100**

### Critical
- [finding with specific fix]

### Warnings
- [finding with specific fix]

### Good
- [what's already well-configured]

### Recommended Actions
1. [Most impactful fix first]
2. [Next fix]
...
```

**Scoring guide:**
- Start at 100, deduct points per finding:
  - Critical: -15 per issue
  - Warning: -5 per issue
- Floor at 0

Be specific in every finding — name the exact file, setting, or server. Don't say "consider reviewing your CLAUDE.md" — say "Lines 15-30 of ~/.claude/CLAUDE.md repeat the subagent delegation rule already stated on line 5."

## Gotchas

- **Don't count the audit skill itself** as context bloat — it's loaded on-demand only when invoked.
- **MCP token estimates are rough** — tool definition sizes vary. Use ~1,500 tokens per tool definition as a baseline.
- **Some "redundant" rules are intentional** — the user may repeat a rule for emphasis because Claude keeps ignoring it. Note the repetition but don't auto-recommend removal without flagging this possibility.
- **Progressive disclosure has a cost too** — if Claude has to read 10 reference files every session anyway, consolidating them back into CLAUDE.md may be cheaper. Judge by actual usage patterns.
- **Deny rules can break workflows** — if the user legitimately needs to read lock files or node_modules for debugging, over-aggressive deny rules cause friction. Recommend but note the tradeoff.
