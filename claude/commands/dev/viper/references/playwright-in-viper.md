# Playwright in Viper — Efficiency Guide

## Scoped Snapshots (CRITICAL)

Viper's DOM is massive and dirty. Full-page `browser_snapshot()` dumps the entire app shell — sidebar menu, client dropdown with hundreds of options, language switcher — burning tokens on noise. **Never use `browser_snapshot()` inside Viper.** Always use scoped snapshots via `browser_run_code`.

### Three-tier snapshot strategy

Try in this order. Use the tightest scope that works for what you're doing:

**Tier 1: `#ebacon-theme-container`** — React apps only (tightest)
All React apps are wrapped in this container. Use this when working with any React-based screen. This isolates just the React component tree — no shell, no Backbone chrome.

**Tier 2: `#viperMain__injectedContainer`** — All app content (medium)
The main content injection point for both Backbone and React pages. Excludes the app shell (header, sidebar, client dropdown) but includes everything in the content area.

**Tier 3: Full `browser_snapshot()`** — Fallback only
Only for the login page or other non-standard views outside the main app shell.

### How to take a scoped snapshot

```javascript
// Use browser_run_code with this pattern:
async (page) => {
  // Try React container first, fall back to injected container
  const react = page.locator('#ebacon-theme-container');
  if (await react.count() > 0) return await react.ariaSnapshot();
  const injected = page.locator('#viperMain__injectedContainer');
  if (await injected.count() > 0) return await injected.ariaSnapshot();
  return 'No content container found — use full browser_snapshot()';
}
```

### Interacting with elements from scoped snapshots

Scoped `ariaSnapshot()` returns text descriptions but NOT `ref=` values like full `browser_snapshot()` does. To interact with elements found in a scoped snapshot:
- Use `browser_click`, `browser_fill_form`, or `browser_type` with the `element` description
- Or use `browser_run_code` with Playwright locators directly (e.g., `page.getByRole()`, `page.locator()`)
- If you truly need `ref` values, take a full `browser_snapshot()` as a one-off, but avoid doing this repeatedly

## Client Shell Switching

**DO NOT** interact with the `#CompanySelector` dropdown in the DOM. Use the sessionStorage pattern from Viper's own integration tests:

```javascript
// Via browser_evaluate — two calls:
// 1. Set the shell
() => { sessionStorage.setItem("header", JSON.stringify({ client: "CLIENT_NAME" })); }
// 2. Reload
() => location.reload()
```

Then wait for the page to settle. This avoids the dropdown entirely (which dumps hundreds of client options into the snapshot).

Source: `tests/integration/utils/helpers.ts` → `waitForShellChange()`

## Navigation

Viper uses **hash-based routing** (Backbone.Router):
- `http://localhost:PORT/index.php/viper/#` — Dashboard
- `http://localhost:PORT/index.php/viper/#employee` — Employee module
- `http://localhost:PORT/index.php/viper/#/payroll` — Payroll
- `http://localhost:PORT/index.php/viper/#companyMenu` — Company Menu

Use `browser_navigate` with the full URL including hash.

Each route triggers a `routeCheck` AJAX call to verify access before rendering.

## Login Flow

The login page has:
- Username: `[name="username"]` input
- Password: `[name="password"]` input
- Submit: `[type="submit"]` button

**Detecting login success:** Wait for the URL to contain `/#` or for the login form elements to disappear.

## Key Selectors

| Element | Selector |
|---------|----------|
| React app content | `#ebacon-theme-container` |
| All injected content | `#viperMain__injectedContainer` |
| Logo/Home | `img#TAGHEADERLOGO` |
| Main Content | `.viperMain__content` |

## Gotchas

- **NEVER use full `browser_snapshot()` inside Viper** unless on the login page. The DOM is too large and will waste thousands of tokens on app shell noise.
- **Session timeout**: 30 minutes of inactivity. Redirects to login with `?SessionExpired=true`.
- **Encryption on login**: The login form encrypts credentials client-side. When automating via Playwright, just fill the form and submit — the JS handles it.
- **Heavy network activity**: Many pages fire dozens of AJAX requests on load. Wait for network to settle before interacting.
- **Hash vs path routing**: Frontend uses hash routing (`/#/path`), backend uses path routing (`/index.php/controller/method`). Don't mix them up.
- **Route check failures**: If a route returns 403, the user may not have permission for that module under the current client shell.
