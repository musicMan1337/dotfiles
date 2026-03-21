---
name: dev:viper
description: Open Viper in Playwright, log in, extract session cookie, and set up both browser + backend MCP access. Triggers on: viper, open viper, start viper, viper session, work in viper
allowed-tools: mcp__plugin_playwright_playwright__*, mcp__viper__*, mcp__sqlsrv__*, mcp__core__*, Bash, Read, Edit, Glob, Grep
---

# Viper Session Orchestrator

You are setting up a dual-access Viper session — Playwright for the frontend, Viper MCP for the backend. Follow the phases below.

## Context

Load these references for the session:
- `!cat ~/dotfiles/claude/commands/viper/references/playwright-in-viper.md`
- `!cat ~/dotfiles/claude/commands/viper/references/ci3-routing.md`
- `!cat ~/dotfiles/claude/commands/viper/references/php-debugging.md`

## Arguments

The user may provide:
- **port** — Custom port (default: 8080). Apply to both the Playwright URL and `viper_set_port`.
- **url** — A specific Viper frontend URL to navigate to after login.
- **client** — A client/shell to switch to after login.

Parse these from the user's message. Do not prompt for them if not provided.

## Phase 1: Launch Browser

1. Set the Viper MCP port if a custom port was provided: call `viper_set_port`.
2. Navigate Playwright to `http://localhost:{port}/` (or the provided URL's origin).
3. Take a snapshot to confirm the login page loaded (full `browser_snapshot()` is fine here — login page is small).

## Phase 2: Wait for Login

The user will log in manually in the browser.

1. Tell the user: "Log in to Viper in the browser. I'll detect when you're done."
2. **Poll for login completion** — use `browser_wait_for` with `time: 5` between checks, then use `browser_evaluate` to check:
   ```
   () => window.location.hash.includes('#')
   ```
3. Once login is detected, proceed immediately.

## Phase 3: Extract Cookie & Set Up Backend

1. Use `browser_evaluate` to read the PHPSESSID cookie:
   ```
   () => document.cookie.split('; ').find(c => c.startsWith('PHPSESSID='))?.split('=')[1]
   ```
2. Call `viper_set_cookie` with the extracted session ID.
3. Confirm: "Session cookie captured. Backend API access is ready."

## Phase 4: Post-Login Navigation

If the user provided a **client** to switch to:
1. Use `browser_evaluate` to set the shell:
   ```
   () => { sessionStorage.setItem("header", JSON.stringify({ client: "CLIENT_NAME" })); }
   ```
2. Reload the page via `browser_evaluate`: `() => location.reload()`
3. Wait for the page to settle.

If the user provided a **url** to navigate to:
1. Navigate Playwright to that URL.
2. Wait for the page to settle.

## Phase 5: Ready

Tell the user the session is ready. Summarize:
- Port in use
- Whether a client shell was set
- Current page
- What they can do: "I can interact with both the frontend (Playwright) and backend (Viper MCP API) directly."

## Ongoing: Scoped Snapshots

**CRITICAL: Never use `browser_snapshot()` once inside the Viper app.** The DOM is massive and will waste thousands of tokens on app shell noise (sidebar, client dropdown with hundreds of entries, etc.).

Always use `browser_run_code` with scoped snapshots instead:

```javascript
async (page) => {
  // Tier 1: React apps — tightest scope
  const react = page.locator('#ebacon-theme-container');
  if (await react.count() > 0) return await react.ariaSnapshot();
  // Tier 2: All injected content — Backbone and React
  const injected = page.locator('#viperMain__injectedContainer');
  if (await injected.count() > 0) return await injected.ariaSnapshot();
  return 'No content container found — use full browser_snapshot()';
}
```

**When to use which tier:**
- `#ebacon-theme-container` — Any React-based screen. Isolates just the React component tree.
- `#viperMain__injectedContainer` — Backbone/legacy pages, or when you need to see both the page menu and the React content.
- Full `browser_snapshot()` — Login page only.

## Ongoing: PHP Debugging

When debugging PHP backend code, use the `debugLog()` helper in `sitehelpers_helper.php`. See the php-debugging reference for full details.

**Workflow:**
1. **Clear the log first** — always start with a clean slate:
   ```bash
   > ~/eBacon/Viper/public/uploaded/debug.log
   ```
   (Or the custom log file if using one.)
2. **Add `debugLog()` calls** to the PHP code being investigated.
3. **Trigger the code** — via `viper_request` (backend) or Playwright (frontend interaction).
4. **Read the log** — `Read` tool on `~/eBacon/Viper/public/uploaded/debug.log`.
5. **Clean up** — remove `debugLog()` calls when done debugging.

**Quick patterns:**
```php
debugLog("hit endpoint");                          // simple trace
debugLog(print_r($data, true));                    // dump variable
debugLog("payload: " . json_encode($payload));     // labeled dump
debugLog($msg, "auth_debug.log");                   // custom log file
```

## Optional: Database Verification via sqlsrv MCP

Only activate when the user explicitly requests database-level verification. This is for cases where you need to confirm PHP backend writes actually landed in the database, or to understand complex data composition (e.g., the case system).

**Setup:** Run a simple test query to confirm the connection works (e.g., `list_tables` or a single-row query).

**Workflow for verifying writes:**
1. Identify which stored procedure the PHP model calls — look in the model file for `$this->db->query()` or similar calls with procedure names.
2. Find the sproc definition in the SQL repo at `~/eBacon/SQL/` — filenames usually match the sproc name, but not always. Use Glob/Grep to search.
3. Read the root procedure to see which tables it inserts/updates. **Start with just the root sproc** — don't crawl sub-procedure call trees unless the root doesn't give enough clarity.
4. Use `sqlsrv` `query` tool to check the relevant tables for the expected data.

**Workflow for understanding complex GETs:**
Some features compose data from both PHP and SQL in convoluted ways (case system is a prime example). The approach:
1. Read the PHP controller/model to see what sprocs are called and how results are composed.
2. Read the root sproc in `~/eBacon/SQL/` to understand the query structure.
3. Use `sqlsrv` to query the underlying tables directly to see raw data, bypassing the composition layer.
4. Only crawl sub-sproc call trees if the root sproc delegates heavily and you can't understand the data flow from it alone.

**Key constraints of sqlsrv MCP:**
- Read-only (SELECT only), no JOINs, single table per query
- Structured queries only (not raw SQL) — use `where`, `order`, `page`, `pageSize` params
- Max 500 rows per page
- Not all tables are configured — use `list_tables` to see what's available

## Optional: Core API Investigation via core MCP

Only activate when the user explicitly requests it. Some Viper PHP controllers forward requests to the Core .NET API — the chain is: **PHP Controller → `CoreApi.php` library → Core.API (dotnet)**.

**How to identify a Core call in PHP:**
Look for `$this->coreApi->get(...)`, `$this->coreApi->post(...)`, etc. in the controller or model. The first argument is the endpoint path (e.g., `"employees/{id}"`). `CoreApi.php` auto-prefixes `api/v1/` if not present.

**Tracing into the Core repo:**
1. Note the endpoint string from the PHP code (e.g., `"employees/{id}"`).
2. Grep the Core repo at `~/eBacon/Core/` for that endpoint string — endpoints are hardcoded in endpoint files, so a grep for the path will find the correct file.
3. Read the endpoint file to understand the .NET side of the request.

**Using the Core MCP directly:**
- `core_status` — check if Core is running (it auto-starts if not)
- `core_search_endpoints` — keyword search across all API endpoints
- `core_read_endpoint` — full details for a specific endpoint (params, schemas, response types)
- `core_api_request` — make requests to Core directly, bypassing Viper's PHP layer
- `core_read_schema` — inspect component schemas

**When this is useful:**
- Debugging data transformation issues between Viper and Core
- Understanding what Core actually returns vs what PHP reshapes
- Hitting Core endpoints directly to isolate whether a bug is in the PHP layer or the .NET layer

## Gotchas

- **PHP 7.2**: Viper is on PHP 7.2. Use the most modern syntax available in 7.2, but nothing newer. Available: short arrays `[]`, null coalescing `??`, spaceship `<=>`, return type declarations, scalar type hints, `list()` destructuring, anonymous classes, group `use` declarations. NOT available (7.3+): named arguments, typed properties, union types, `match`, arrow functions `fn() =>`, null coalescing assignment `??=`, trailing commas in function calls, `str_contains`/`str_starts_with`/`str_ends_with`, enums, fibers, readonly properties.
- **DO NOT** try to automate the login form. The user logs in manually — credentials are encrypted client-side and we don't handle that.
- **NEVER use full `browser_snapshot()` inside the app.** Always scope to `#ebacon-theme-container` or `#viperMain__injectedContainer`. See reference doc for details.
- **Client shell switch**: NEVER use the `#CompanySelector` dropdown directly. Always use the `sessionStorage` + reload pattern — the dropdown dumps hundreds of clients into the snapshot.
- **Cookie extraction**: `document.cookie` only exposes non-HttpOnly cookies. PHPSESSID in Viper's local dev is accessible this way. If it ever fails, ask the user to paste the cookie value manually.
- **Session timeout**: 30 minutes. If the session dies mid-work, the user needs to log in again and you need to re-extract the cookie.
- **Hash routing**: Frontend URLs use `/#/path`. Backend URLs use `/index.php/controller/method`. Don't cross them.
- **Network settling**: After any navigation or shell change, wait for network activity to stop before interacting. Viper pages fire many AJAX requests.
- **Poll gently**: When waiting for login, don't spam snapshots. ~5 second intervals are fine.
