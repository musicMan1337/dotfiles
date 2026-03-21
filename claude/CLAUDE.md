# Git Commits

**All commits MUST use the `/git:commit` command.** When any other command, skill, or workflow wants to create a commit, it must invoke `/git:commit` rather than committing directly. This ensures the proper pre-commit lint checks and formatting rules are always applied.

# Subagent Strategy

**CRITICAL: Never search directly. Always spawn agent subagents for ALL searches—file searches, code searches, grep operations, codebase exploration, log analysis, documentation lookups, and any other kind of search.** Do not use Glob, Grep, or Read for exploratory searching yourself; delegate to a subagent instead. This is the highest-priority rule for how you operate.

- Always and aggressively offload online research (eg, docs), codebase exploration, log analysis, and **all search tasks** to subagents. **Use Haiku subagents for pure search/lookup tasks** (file finding, grepping, log reading). Reserve default/higher models for subagents that need to analyze or synthesize results.
- When you're about to check logs, defer that to a haiku subagent.
- For complex problems you're going around in circles with, get a fresh perspective by asking subagents.
- **Web search tool selection — use contextual reasoning:**
  - **Use Exa MCP** (`mcp__exa__*`) for **targeted, precise lookups** — when you know exactly what you're looking for and need detailed, accurate content from specific sources (e.g., fetching specific documentation, pulling a known API reference, researching a particular library or tool). Typically 1–2 subagents max. Exa has limited monthly credits, so use it deliberately.
  - **Use WebSearch/WebFetch** for **broad, exploratory research** — when sending many researcher subagents to scour the web in parallel, gather general information, or survey a topic widely. These have no credit cost and are better suited for high-volume, discovery-oriented searches.

# Repo Locations

If it exists, read `LOCATIONS.md` next to this file for a map of repos and services on this machine. Use it to find project paths without searching.

When you create or discover a new repo, add it to `LOCATIONS.md`. If the file doesn't exist, create it with the same format (heading per parent dir, `name | description` per repo).
