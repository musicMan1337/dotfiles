---
name: mcp:add-global
model: haiku
allowed-tools: Bash(cat:*), Read, Edit
description: Add an MCP server to the global config (~/.claude.json). Triggers on: add global mcp, global mcp server, add mcp globally, register mcp server
---

# Add Global MCP Server

Add an MCP server entry to the **global** config so it's available in all sessions.

## Arguments

The user should provide:
- **name** — server name (the key in mcpServers)
- **command** — executable (e.g., `node`, `npx`, `python3`)
- **args** — arguments array (e.g., the path to the server script)
- **env** — optional environment variables object

If any required info is missing, ask for it.

## Config Location

**File:** `~/.claude.json`
**Key:** `mcpServers`

This is the ONLY file to edit. Do not search for it — it's always at `~/.claude.json`.

## Steps

1. Read `~/.claude.json` with the Read tool.
2. Parse the existing `mcpServers` object (create it if missing).
3. Add the new server entry. Standard format:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "node",
      "args": ["/path/to/server/index.js"],
      "env": {}
    }
  }
}
```

4. Write the updated JSON back with Edit, preserving all other keys.
5. Tell the user to restart Claude Code or run `/mcp:restart` to pick up the new server.

## Gotchas

- **Do not search for the config file.** It is always `~/.claude.json`. Period.
- **Preserve existing keys.** The file has many non-MCP keys (theme, numStartups, etc.). Only touch `mcpServers`.
- **HTTP servers use a different format.** If the user provides a URL instead of a command, use `{ "type": "http", "url": "..." }` instead of the stdio format.
- **Server names must be unique.** If the name already exists, warn the user before overwriting.
