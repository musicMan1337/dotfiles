---
name: dev:core
description: Start Core.API, discover endpoints, make requests, and monitor logs for autonomous .NET development. Triggers on: core, work in core, core dev, start core, core api
allowed-tools: mcp__core__*, Bash, Read, Edit, Glob, Grep
---

# Core Dev Session

You are setting up an autonomous development session against the eBacon Core .NET API. The Core MCP gives you full control: start/stop the server, search endpoints, read schemas, fire requests, and monitor console output — all without leaving the editor.

## Phase 1: Ensure Core Is Running

1. Call `core_status` to check if the API is up.
2. If it's down, call `core_status` with `start: true`. The MCP spawns `dotnet run` and polls until ready (up to 120s). The process runs detached — it survives MCP restarts.
3. Confirm the API is healthy before proceeding.

If the user has made code changes since the last start, use `core_restart` instead to pick up the new build.

## Phase 2: Orient

Understand what the user wants to work on, then use discovery tools to build context:

- `core_list_tags` — overview of all API categories and endpoint counts
- `core_search_endpoints` — keyword search across paths, tags, summaries (e.g., "payroll", "employee")
- `core_read_endpoint` — full details for a specific endpoint (params, request body, response schemas)
- `core_read_schema` — inspect DTO/model structures (e.g., "EmployeeDto")
- `core_refresh_spec` — re-fetch the OpenAPI spec after rebuilding or adding endpoints

Build a mental model of the relevant endpoints before making changes.

## Phase 3: Autonomous Dev Loop

This is the core workflow. Repeat as needed:

1. **Make code changes** — Edit files in `~/eBacon/Core/` using Edit tool.
2. **Restart the server** — Call `core_restart` so it picks up the new build. Wait for it to report healthy.
3. **Refresh the spec** — Call `core_refresh_spec` if you added/changed endpoints or schemas.
4. **Fire a request** — Call `core_api_request` with the appropriate method, path, query params, and/or body.
5. **Read console output** — The server logs to stdout. Use `core_status` to confirm it's still running. If the request failed or returned unexpected results, check the response carefully and iterate.

**This loop makes development fully autonomous** — you can write code, rebuild, test, and debug without the user touching anything.

## Key Tools Reference

| Tool | Purpose |
|------|---------|
| `core_status` | Check if running, optionally start |
| `core_restart` | Stop + restart (picks up code changes) |
| `core_search_endpoints` | Keyword search across all endpoints |
| `core_read_endpoint` | Full endpoint details (params, schemas) |
| `core_read_schema` | Inspect a DTO/model by name |
| `core_api_request` | Fire HTTP requests directly |
| `core_list_tags` | List all API categories |
| `core_refresh_spec` | Re-fetch OpenAPI spec after changes |

## Gotchas

- **Always restart after code changes.** `dotnet run` compiles on start — if you edit C# files, the running server has stale code. Call `core_restart` before testing.
- **Refresh spec after endpoint changes.** The MCP caches the OpenAPI spec. If you add, rename, or modify endpoints, call `core_refresh_spec` or your discovery results will be stale.
- **API key is auto-loaded.** The MCP reads the key from `appsettings.env.json`. You don't need to pass auth headers manually in `core_api_request`.
- **Base URL is `http://localhost:5205`.** Don't change this unless the user explicitly provides a different port.
- **Startup can take up to 120s.** The .NET build + startup is not instant. Don't assume failure if `core_status` with `start: true` takes a while.
- **The dotnet process is detached.** It keeps running after the MCP server or Claude session ends. The user may need to manually kill it if it gets stuck (`lsof -i :5205`).
- **PHP → Core chain.** Some Viper PHP controllers forward to Core via `CoreApi.php`. If you're tracing a request that originates in Viper, the endpoint path in PHP (e.g., `"employees/{id}"`) maps to `/api/v1/employees/{id}` in Core. Use `core_search_endpoints` to find the .NET side.
