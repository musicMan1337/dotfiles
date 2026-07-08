# CRITICAL: All output messages

Be extremely concise. Sacrifice grammar for the sake of concision.

- No preamble ("I'll", "Let me", "Sure"). Start with the action or answer.
- Don't restate the question.
- Drop articles (a/an/the) and filler when meaning survives.
- One sentence beats two. Fragments beat sentences.
- Skip pleasantries ("Great!", "Perfect!", "Happy to help").

- **No end-of-turn recaps.** Overrides the system prompt's "end-of-turn summary" rule. End with a short "done" marker (≤5 words, e.g. "Done.", "Built and lint-clean."), not a summary of what changed.

- **NEVER use the em-dash character (`—`, U+2014) for ANY purpose, EVER.** Not in chat output, not in code, not in file contents, not in commit messages, not in comments. Use `,` `;` `:` `(` `)` or `.` instead, whichever fits. This rule has no exceptions. (En-dash `–` is allowed for numeric ranges only, e.g. `1–2`.)

# Git Commits

Conventional Commits, terse; the format spec lives in `/git:commit`, which is the entry point for all commits (other skills/workflows invoke it too). It delegates nontrivial diffs to the `committer` agent to keep large diffs out of the main session; a trivial diff already understood in-session may be committed directly in the same format.

# Working Defaults

- **Bug reports: investigate first.** When I report a bug, paste an error, or describe broken behavior, the deliverable is root cause + proposed fix, NOT a code change. Do not edit code until I ask for the fix (exception: I explicitly said to fix it up front, e.g. "fix the bug yourself").
- **Nothing is "done" until it's exercised.** A new config value must be shown to be consumed by the code that reads it; a new script must run once cleanly; a new endpoint must be hit. Run /verify for nontrivial changes before declaring completion. "I wrote it" is not "it works."
- **Never assert DB behavior from inference.** If a SQL MCP is connected, check the actual schema/sproc/data before claiming how the database behaves or writing queries against guessed column names.
- **Generated files: print the path, nothing else.** When you generate a scratchpad/output file (HTML, report, export), print its absolute path and stop. Never auto-open a browser or app; I open files myself via URL or file explorer.

# Subagent Strategy

Goal: keep the main session's context lean (premium 1M model; every token in context is re-billed each turn) so it stays a sharp orchestrator over a long session, while staying under the AV concurrency ceiling below. Delegate to subagents when a search, analysis, or implementation is broad, parallelizable, or would dump bulky churn into context (log sweeps, codebase exploration, doc research, multi-file edits and their read→edit→verify→fix loop). Direct Glob/Grep/Read/Edit is fine for targeted work you can finish in a couple of calls; a delegated one-line grep or edit costs more than a direct one.

- **Concurrency cap (Sophos CryptoGuard):** max 4 concurrent subagents per session AND max 6 machine-wide across ALL sessions (`SUBAGENT_CAP` / `SUBAGENT_GLOBAL_CAP`; the subagent-gate hook enforces both on Agent/Task spawns). **Teammate/agent-team fleets count toward the machine-wide cap**: each teammate is its own session, so N teammates with their own subagents burst the aggregate file I/O even when every session is individually under 4; that is exactly the topology that tripped CryptoGuard on 2026-07-01. Size fleets accordingly (few, longer-lived teammates over wide fan-outs). Structure fan-outs to fit: prefer ONE aggregate agent given the full file list (single `rg`/`jq` pass) over many small sweepers; subagents return results in their final message, never via scratchpad temp files; for repeated analysis over large logs, index once (sqlite / rag MCP) and query the index. Workflow-tool `agent()` calls bypass the hook, so self-limit Workflow scripts to 4 concurrent (batch with small `parallel()` groups or a slot counter).
- **Nested spawns are gated.** Only catch-all types (`general-purpose`/`claude`) hold the Agent/Task tool, so pinned agents never nest by accident; when a catch-all spawns a child, that spawn re-enters this hook and claims slots like any other (verified 2026-07-08), so a nested tree stays under the machine-wide cap of 6 (no extra CryptoGuard exposure) though it shares that budget with every session/teammate. Prefer Workflow for structured fan-out; nest only when a catch-all orchestrator must fan out to pinned workers.
- **Model routing lives in the pinned agent definitions** (`~/.claude/agents/`; tier policy: `dotfiles/claude/TIERS.md`): `reader` (haiku) for pure search/lookup/log reading, `classifier` (sonnet) for read+label fan-outs, `committer` (haiku) for commits, `coder` (opus) for scoped implementation, `planner`/`synthesizer`/`plan-auditor`/`security-auditor` (opus) for heavy reasoning. Pick the cheapest agent that can do the job; the subagent-gate denies spawns that neither name a pinned agent nor pass an explicit `model` param.
- **On Opus, delegate coding to `coder` even though `coder` is also Opus.** The win is context hygiene, not tier savings: a scoped change's file reads, edits, verify/Bash output, and dead-ends all stay inside the subagent and only its terse report returns, so the main session stays a lean orchestrator that can run long. Spawn it once scope is clear (a plan step, a port, a refactor, a bug fix with root cause already found). Inline the edit only when it's trivial (a line or two already in context) or needs live back-and-forth with me; don't spawn `coder` for mechanical one-offs a cheaper path handles.
- For complex problems you're going around in circles with, get a fresh perspective from a fresh-context subagent.
- **Web tool facts** (choose per task): Firecrawl (`/firecrawl:firecrawl-cli`) returns clean markdown and handles JS rendering and bot blocks that native WebFetch often fails on; suited to broad parallel research. Exa MCP (`mcp__exa__*`) is precise for known sources but has limited monthly credits; spend deliberately.

# Repo Locations

If it exists, read `LOCATIONS.md` next to this file for a map of repos and services on this machine. Check it first for project paths; fall back to searching when an entry is missing or stale (the filesystem is ground truth).

When you create or discover a new repo, add it to `LOCATIONS.md`. If the file doesn't exist, create it with the same format (heading per parent dir, `name | description` per repo).

# Viper Monorepo

CI hard-fails on undeclared internal workspace deps: when importing `@tagemployerservices/*` in a component, the package must be listed in that component's `package.json` `dependencies` (add it if absent).

# Numbered Options

When presenting choices in plain text (approve/deny/alter, next steps, etc.), number each option so the user can reply by number. If a skill or tool uses the AskUserQuestion tool with multiple-choice options, use that instead; it already provides structured selection. Numbered options are for free-text responses only.

**This applies even for "obvious" binary choices.** Never end a turn with bare trailing questions like "Approve?", "Approve? Request changes?", or "Sound good?"; always enumerate, even if it's just two options.

Example, instead of: "Approve this or make changes?"
Write:
1. Approve
2. Make changes

# Claude in Chrome: target the "Claude" profile only

Before any browser automation, call `list_connected_browsers` and `select_browser` the **"Claude"** profile (the dedicated Chrome profile that has the Claude extension installed). Never drive my main browsing profile. If no "Claude" browser is connected, stop and tell me to open a "Claude"-profile window; do NOT fall back to whatever Chrome is connected.
