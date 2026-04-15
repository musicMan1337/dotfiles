# Git Commits

**All commits MUST use the `/git:commit` command.** When any other command, skill, or workflow wants to create a commit, it must invoke `/git:commit` rather than committing directly. This ensures consistent Conventional Commits formatting (terse caveman-style messages).

# Subagent Strategy

**CRITICAL: Never search directly. Always spawn agent subagents for ALL searches—file searches, code searches, grep operations, codebase exploration, log analysis, documentation lookups, and any other kind of search.** Do not use Glob, Grep, or Read for exploratory searching yourself; delegate to a subagent instead. This is the highest-priority rule for how you operate. If you catch yourself about to call Glob, Grep, or WebSearch directly instead of spawning a subagent, stop — that impulse is wrong every time.

- Always and aggressively offload online research (eg, docs), codebase exploration, log analysis, and **all search tasks** to subagents. **Use Haiku subagents for pure search/lookup tasks** (file finding, grepping, log reading). Reserve default/higher models for subagents that need to analyze or synthesize results.
- When you're about to check logs, defer that to a haiku subagent.
- For complex problems you're going around in circles with, get a fresh perspective by asking subagents.
- **Web search tool selection — use contextual reasoning:**
  - **Use Firecrawl** (`/firecrawl:firecrawl-cli`) for **broad, exploratory research** — when sending many researcher subagents to scour the web in parallel, gather general information, scrape pages, or survey a topic widely. Firecrawl returns clean LLM-optimized markdown, handles JS rendering, and bypasses common blocks. **Firecrawl replaces WebSearch/WebFetch** — do not use WebSearch or WebFetch directly when Firecrawl is available.
  - **Use Exa MCP** (`mcp__exa__*`) for **targeted, precise lookups** — when you know exactly what you're looking for and need detailed, accurate content from specific sources (e.g., fetching specific documentation, pulling a known API reference, researching a particular library or tool). Exa excels when the URL or exact source is already known. Typically 1–2 subagents max. Exa has limited monthly credits, so use it deliberately.

# Large File Reading

When reading a file, first check its line count. If a file exceeds 2,000 lines, do NOT read it in a single call — use the `offset` and `limit` parameters to read it in chunks of 2,000 lines or fewer, ensuring nothing is missed.

# Repo Locations

If it exists, read `LOCATIONS.md` next to this file for a map of repos and services on this machine. Use it to find project paths without searching.

When you create or discover a new repo, add it to `LOCATIONS.md`. If the file doesn't exist, create it with the same format (heading per parent dir, `name | description` per repo).

# Numbered Options

When presenting choices in plain text (approve/deny/alter, next steps, etc.), number each option so the user can reply by number. If a skill or tool uses the AskUserQuestion tool with multiple-choice options, use that instead — it already provides structured selection. Numbered options are for free-text responses only.

Example — instead of: "Approve this or make changes?"
Write:
1. Approve
2. Make changes
