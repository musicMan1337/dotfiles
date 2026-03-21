---
name: mcp:add-local
model: haiku
allowed-tools: Bash(cat:*), Read, Edit, Write
description: Add an MCP server scoped to the current project (.mcp.json). Triggers on: add local mcp, project mcp server, add mcp to project, add mcp locally
---

# Add Project-Local MCP Server

Add an MCP server entry to the **project-level** config so it's only available in this project.

## Arguments

The user should provide:
- **name** — server name (the key in mcpServers)
- **command** — executable (e.g., `node`, `npx`, `python3`)
- **args** — arguments array (e.g., the path to the server script)
- **env** — optional environment variables object

If any required info is missing, ask for it.

## Config Location

**File:** `.mcp.json` in the project root (the current working directory)
**Key:** `mcpServers`

This is the ONLY file to edit. Do not search for it — create it if it doesn't exist.

## Steps

1. Check if `.mcp.json` exists in the project root.
2. If it exists, read it. If not, start with `{ "mcpServers": {} }`.
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

4. Write the updated JSON back, preserving all other keys.
5. Tell the user to restart Claude Code or run `/mcp:restart` to pick up the new server.
6. Remind the user that `.mcp.json` is designed to be committed to version control — if they don't want that, add it to `.gitignore`.

## Gotchas

- **Do not search for the config file.** It is always `.mcp.json` in the project root.
- **Claude Code prompts for approval** before using project-scoped servers. This is expected — the user will see a prompt on next session start.
- **HTTP servers use a different format.** If the user provides a URL instead of a command, use `{ "type": "http", "url": "..." }` instead of the stdio format.
- **Server names must be unique.** If the name already exists in `.mcp.json`, warn the user before overwriting.
- **Environment variable expansion works.** Values like `${HOME}` or `${VAR:-default}` are expanded at runtime.
