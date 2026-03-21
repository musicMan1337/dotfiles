---
name: mcp:restart
model: haiku
allowed-tools: Bash(claude mcp:*), Bash(cat ~/.claude.json:*), Bash(python3:*)
description: Restart an MCP server in place without losing session context. Triggers on: restart mcp, reload mcp, reconnect mcp, mcp restart, bounce mcp server
---

## Input

**Server hint:** $ARGUMENTS

The user provides a short name or keyword that identifies the MCP server (e.g., "procore", "sql", "playwright"). Match it against the server names in the config — it doesn't need to be exact.

## Steps

1. Identify the server: Read the MCP server config from `~/.claude.json` and find the server whose name contains or matches the user's hint. If multiple match, list them and ask which one. If none match, show available servers.

2. **Try `_reload` first.** Call the server's `_reload` tool (e.g., `mcp__servername___reload`). This hot-reloads code and env vars without breaking the stdio pipe — it's faster and more reliable than a full restart.

3. **If `_reload` succeeds**, report success and stop. No further action needed.

4. **If `_reload` doesn't exist or fails**, fall back to the full restart:
   a. Extract the server's full JSON config object.
   b. Run `claude mcp remove <server-name>` to disconnect it.
   c. Run `claude mcp add-json <server-name> '<config-json>'` to reconnect it with the same config.
   d. Report success with the server name.

## Gotchas

- **Prefer `_reload` over full restart.** Servers built with the bootstrap pattern (see `/mcp:create`) have a `_reload` tool that swaps code without killing the process. This avoids the flaky stdio reconnection.
- **`_reload` only swaps implementations.** If the user added or removed tools (not just changed handler logic), a full restart is still needed. Mention this if `_reload` succeeds but the user expected new tools to appear.
- **Scope matters:** Servers can be in local (`~/.claude.json`), project (`.mcp.json`), or user scope. The remove/add must target the same scope. Default to local scope unless the server is found in `.mcp.json`.
