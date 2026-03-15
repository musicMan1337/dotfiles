# Subagent Strategy

**CRITICAL: Never search directly. Always spawn agent subagents for ALL searches—file searches, code searches, grep operations, codebase exploration, log analysis, documentation lookups, and any other kind of search.** Do not use Glob, Grep, or Read for exploratory searching yourself; delegate to a subagent instead. This is the highest-priority rule for how you operate.

- Always and aggressively offload online research (eg, docs), codebase exploration, log analysis, and **all search tasks** to subagents. **Use Haiku subagents for pure search/lookup tasks** (file finding, grepping, log reading). Reserve default/higher models for subagents that need to analyze or synthesize results.
- When you're about to check logs, defer that to a haiku subagent.
- For complex problems you're going around in circles with, get a fresh perspective by asking subagents.
- **When a search requires the web, always use the Exa MCP tools (not WebSearch/WebFetch).** Exa is the preferred web search provider—route all web lookups through it.
