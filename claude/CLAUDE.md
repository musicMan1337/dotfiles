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

**All commits MUST use the `/git:commit` command.** When any other command, skill, or workflow wants to create a commit, it must invoke `/git:commit` rather than committing directly. This ensures consistent Conventional Commits formatting with terse messages.

# Working Defaults

- **Bug reports: investigate first.** When I report a bug, paste an error, or describe broken behavior, the deliverable is root cause + proposed fix, NOT a code change. Do not edit code until I ask for the fix (exception: I explicitly said to fix it up front, e.g. "fix the bug yourself").
- **Nothing is "done" until it's exercised.** A new config value must be shown to be consumed by the code that reads it; a new script must run once cleanly; a new endpoint must be hit. Run /verify for nontrivial changes before declaring completion. "I wrote it" is not "it works."
- **Never assert DB behavior from inference.** If a SQL MCP is connected, check the actual schema/sproc/data before claiming how the database behaves or writing queries against guessed column names.
- **Generated files: print the path, nothing else.** When you generate a scratchpad/output file (HTML, report, export), print its absolute path and stop. Never auto-open a browser or app; I open files myself via URL or file explorer.

# Subagent Strategy

**CRITICAL: Never search directly. Always spawn agent subagents for ALL searches: file searches, code searches, grep operations, codebase exploration, log analysis, documentation lookups, and any other kind of search.** Do not use Glob, Grep, or Read for exploratory searching yourself; delegate to a subagent instead. This is the highest-priority rule for how you operate. If you catch yourself about to call Glob, Grep, or WebSearch directly instead of spawning a subagent, stop; that impulse is wrong every time.

- **Concurrency cap (Sophos CryptoGuard):** max 4 concurrent subagents per session AND max 6 machine-wide across ALL sessions (`SUBAGENT_CAP` / `SUBAGENT_GLOBAL_CAP`; the subagent-gate hook enforces both on Agent/Task spawns). **Teammate/agent-team fleets count toward the machine-wide cap**: each teammate is its own session, so N teammates with their own subagents burst the aggregate file I/O even when every session is individually under 4; that is exactly the topology that tripped CryptoGuard on 2026-07-01. Size fleets accordingly (few, longer-lived teammates over wide fan-outs). Structure fan-outs to fit: prefer ONE aggregate agent given the full file list (single `rg`/`jq` pass) over many small sweepers; subagents return results in their final message, never via scratchpad temp files; for repeated analysis over large logs, index once (sqlite / rag MCP) and query the index. Workflow-tool `agent()` calls bypass the hook, so self-limit Workflow scripts to 4 concurrent (batch with small `parallel()` groups or a slot counter).
- Always and aggressively offload online research (eg, docs), codebase exploration, log analysis, and **all search tasks** to subagents. **Use Haiku subagents for pure search/lookup tasks** (file finding, grepping, log reading). Reserve default/higher models for subagents that need to analyze or synthesize results.
- When you're about to check logs, defer that to a haiku subagent.
- For complex problems you're going around in circles with, get a fresh perspective by asking subagents.
- **Web search tool selection, use contextual reasoning:**
  - **Use Firecrawl** (`/firecrawl:firecrawl-cli`) for **broad, exploratory research**: when sending many researcher subagents to scour the web in parallel, gather general information, scrape pages, or survey a topic widely. Firecrawl returns clean LLM-optimized markdown, handles JS rendering, and bypasses common blocks. **Firecrawl replaces WebSearch/WebFetch**: do not use WebSearch or WebFetch directly when Firecrawl is available.
  - **Use Exa MCP** (`mcp__exa__*`) for **targeted, precise lookups**: when you know exactly what you're looking for and need detailed, accurate content from specific sources (e.g., fetching specific documentation, pulling a known API reference, researching a particular library or tool). Exa excels when the URL or exact source is already known. Typically 1–2 subagents max. Exa has limited monthly credits, so use it deliberately.

# Large File Reading

When reading a file, first check its line count. If a file exceeds 2,000 lines, do NOT read it in a single call; use the `offset` and `limit` parameters to read it in chunks of 2,000 lines or fewer, ensuring nothing is missed.

# Repo Locations

If it exists, read `LOCATIONS.md` next to this file for a map of repos and services on this machine. Use it to find project paths without searching.

When you create or discover a new repo, add it to `LOCATIONS.md`. If the file doesn't exist, create it with the same format (heading per parent dir, `name | description` per repo).

# Monorepo Internal Dependencies

When adding a new import from an internal workspace package (e.g., `@tagemployerservices/ebacon-ui-utils`) to a component, always verify the imported package is listed in that component's `package.json` `dependencies`. Vite externalizes only declared deps; missing declarations cause build failures in CI. Add the dependency if absent.

# Terminal Tab Renaming (Warp only)

When the user asks to rename the terminal tab, set the title to **EXACTLY** this format, no deviation:

```
{branch}
```

`{branch}` = current git branch, with a leading `Derek/` stripped (own branches only; other people's prefixes like `Josh/` are kept so authorship stays visible). Examples: `Derek/345279-FolderInheritance` → `345279-FolderInheritance`; `Josh/9596-BulkPunch` → `Josh/9596-BulkPunch`.

**Hard rules (this is a strictly controlled action):**

- **Only when inside Warp.** Gate on the env var `TERM_PROGRAM == WarpTerminal`. If it's anything else, do nothing, no message, no fallback. The OSC title is meaningless/wrong outside Warp.
- **The format is fixed.** Never improvise a shorter, longer, or "nicer" name. No task descriptions, no emoji, no truncation, no repo name, no stripping the `Name/` prefix. `{branch}` only.
- **Derive the branch from git, don't guess it.** Run the one-liner below; it computes the branch and only fires under Warp:

```bash
[ "$TERM_PROGRAM" = "WarpTerminal" ] && b="$(git rev-parse --abbrev-ref HEAD)" && rename-tab "${b#Derek/}"
```

`rename-tab` is defined in `bash/.bashrc.d/functions.sh` (sourced by zsh); it emits an OSC 0 title to the tab's pty (walks the process tree, so it works from the Bash tool's detached shell). Requires `WARP_DISABLE_AUTO_TITLE=true` (set in `zsh/.zshrc.d/exports.sh`). If the title doesn't change, the tab was manually renamed in Warp (Warp pins those and ignores OSC); mention that rather than retrying.

# Numbered Options

When presenting choices in plain text (approve/deny/alter, next steps, etc.), number each option so the user can reply by number. If a skill or tool uses the AskUserQuestion tool with multiple-choice options, use that instead; it already provides structured selection. Numbered options are for free-text responses only.

**This applies even for "obvious" binary choices.** Never end a turn with bare trailing questions like "Approve?", "Approve? Request changes?", or "Sound good?"; always enumerate, even if it's just two options.

Example, instead of: "Approve this or make changes?"
Write:
1. Approve
2. Make changes

# Claude in Chrome — target the "Claude" profile only

Before any browser automation, call `list_connected_browsers` and `select_browser` the **"Claude"** profile (the dedicated Chrome profile that has the Claude extension installed). Never drive my main browsing profile. If no "Claude" browser is connected, stop and tell me to open a "Claude"-profile window — do NOT fall back to whatever Chrome is connected.
