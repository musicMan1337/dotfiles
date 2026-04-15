# Channel artifact — troubleshooting

Every failure mode we've hit while building this pattern, with the one-liner fix.

## Setup / launch

### `/mcp` shows `<plugin-name> · ✘ failed`

Three common causes, in order:

1. **Port already in use.** Another bun process owns the port. Check with `lsof -ti:<port>` → `kill <pid>`. Then `/mcp` reconnect.
2. **Project `.mcp.json` wasn't loaded.** The server registration is project-scoped — Claude must have been launched from the project root directory. Verify with `pwd` before `claude --dangerously-load-development-channels server:<name>`.
3. **First-time approval prompt dismissed.** Project MCPs require user approval on first run. If you hit Escape or the prompt never appeared, the server stays disabled. `/mcp` → select the server → "enable".

### `Connection closed` or `MCP error -32000` right after launch

The server process crashed. Likely causes:

- **Channel meta contains non-strings.** Numbers, nulls, booleans in the `meta` object cause Zod validation to throw in Claude's channel handler. The MCP transport closes silently after the first notification. Always `String(value)` every meta field and drop keys where value is null/undefined via spread:
  ```ts
  ...(comment.anchorNodeId ? { anchor_node_id: comment.anchorNodeId } : {}),
  ```
- **`Bun.serve` threw uncaught.** If `EADDRINUSE` isn't caught, the process exits. Wrap `Bun.serve` in try/catch; on `EADDRINUSE`, log a warning and `process.stdin.resume()` so stdio MCP stays alive.

### Pin a comment but nothing happens in Claude

The UI saved the comment but the channel notification didn't reach any session. Diagnose:

1. Check `lsof -ti:<port> | xargs ps -p` — what's the PPID?
   - **PPID = 1**: orphan bun. Started standalone (`bun server.ts`) or survived its parent. No Claude is listening on its stdio. `kill <pid>` and relaunch with `claude --dangerously-load-development-channels server:<name>`.
   - **PPID = Claude's PID**: Claude spawned it, stdio is connected. Should work. Check `/mcp` for connection status and tool list.
2. If `/mcp` shows the server healthy but pins still don't trigger, look at the channel session's terminal output — a `<channel source="<name>">` event should print when a comment arrives. If not, the notification is being sent but not delivered (rare; usually the meta-types bug).
3. If you recently edited `server.ts`: **edits don't hot-reload**. `/mcp` reconnect to respawn.

### Orphan bun stays after Claude exits

Claude's spawned bun can outlive the session if the MCP SDK doesn't cleanly close stdin. Always clean up before relaunching:
```bash
kill $(lsof -ti:<port>) 2>/dev/null
```

## UI rendering

### Sankey is blank, no errors

d3-sankey `0.12.x` UMD expects `d3.array` and `d3.shape` namespaces (d3 v4 layout). d3 v7 is flat — those namespaces don't exist, so `d3.sankey` is undefined and `renderSankey()` throws inside `render()`, silently stopping everything afterward.

Fix: use ESM imports, spread the frozen namespace before adding extras:

```html
<script type="module">
  import * as d3mod from "https://cdn.jsdelivr.net/npm/d3@7/+esm";
  import { sankey, sankeyLinkHorizontal } from "https://cdn.jsdelivr.net/npm/d3-sankey@0.12.3/+esm";
  window.d3 = { ...d3mod, sankey, sankeyLinkHorizontal };
  window.dispatchEvent(new Event("d3-ready"));
</script>
```

### `Cannot assign to property 'sankey' of [object Module]`

ESM module namespaces are frozen. Can't do `d3.sankey = sankey`. Spread into a plain object first:
```ts
window.d3 = { ...d3mod, sankey, sankeyLinkHorizontal };
```

### `Error: missing: 0` inside d3-sankey

`.nodeId(d => d.id)` tells sankey to look up nodes by string `id`, but links use numeric indices. Switch links to string ids:
```ts
// BROKEN:
{ source: 0, target: 1, value: 100 }
// WORKING:
{ source: "landing", target: "pricing", value: 100 }
```

### Sankey rects render with no fill (invisible)

CSS variables (`var(--green)`) don't resolve as SVG attribute values — only as CSS `style` rules. Use literal hex in `.attr("fill", ...)`:
```ts
// BROKEN:
.attr("fill", "var(--green)")
// WORKING:
.attr("fill", "#16a34a")
```

### Whole page below header is blank

Usually a chain reaction: `renderSankey()` throws, and the rest of `render()` never runs. Check DevTools console for the first error. Common culprits are the three d3-sankey issues above.

## Comments / pins

### Delete returns 404

The running bun is stale — `server.ts` was edited but the server wasn't respawned. `/mcp` reconnect, OR if an orphan is holding the port, `kill $(lsof -ti:<port>)` and reconnect.

### Claude responds to comments I deleted

`deliverChannel` was called on the DELETE path. It must NOT be — only adds should notify Claude.

### Pin drops but panel opens in the wrong place

The panel uses `position: absolute` with `left/top` computed from click coords. Check:
- The click event is `e.pageX`/`e.pageY`, not `e.clientX`/`e.clientY` (pageX/Y include scroll).
- `positionPanelNear` clamps against `window.scrollY + window.innerHeight`.

### Floating pin marker is hard to click

Default size too small. Bump to 22px with 2px white border, keep delete visible on active:
```css
.floating-pin .delete-btn { width: 22px; height: 22px; ... }
.floating-pin:hover .delete-btn,
.floating-pin.active .delete-btn { opacity: 1; }
```

## Multi-instance / state-sharing

### Two Claude sessions want the same channel — one fails

Expected. First session owns HTTP port; second hits `EADDRINUSE`, logs `running stdio-only`, serves tool calls against shared state files. Both sessions can mark comments addressed, update nodes. Only first session's bun emits WebSocket broadcasts.

### WebSocket keeps disconnecting

Server was restarted. Client reconnects on close with 2s backoff. If reconnects fail continuously, server is down — check `lsof -ti:<port>`.

## Useful diagnostics

```bash
# Is anything on the port?
lsof -ti:<port>

# Who owns it?
lsof -ti:<port> | xargs ps -p

# PPID = 1 → orphan. PPID = claude PID → healthy spawn.

# Check MCP process tree
pgrep -fl "bun server.ts"

# Force a clean reset
kill $(lsof -ti:<port>) 2>/dev/null
# Then in Claude: /mcp → reconnect
```
