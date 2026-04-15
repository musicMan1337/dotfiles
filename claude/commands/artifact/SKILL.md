---
name: artifact
description: >
  Build HTML artifacts for brainstorming, design exploration, prototyping, and data visualization.
  Three levels: static (variations/explainers), interactive (Bun hot-reload + click-to-annotate + JSON export),
  and channel (bidirectional Claude Code communication via channel plugin — comments go straight back to Claude).
  Triggers on: build an artifact, make an artifact, artifact for, design variations, interactive artifact,
  make it interactive, explore this visually, make me variations, I'll know it when I see it,
  show me options, channel artifact, using channels, connect artifact to claude, make a dashboard I can chat with,
  turn this into a channel artifact, annotate and have Claude respond, pin comments on data,
  prototype with artifacts, presentation variations, slide variations
---

# Artifact

Build self-contained HTML artifacts for exploration, design, visualization, and prototyping. Three levels of interactivity, each building on the previous.

## Level classification

Detect the level from the user's language:

| Signal | Level | What you build |
|--------|-------|----------------|
| "variations", "options", "designs", "explore", "brainstorm", "explainer", "presentation", or no interactivity mentioned | **Level 1 — Static** | Single HTML file with variations or an interactive explainer |
| "interactive", "click", "comment", "feedback", "hot reload", "editable", "annotate" | **Level 2 — Interactive** | Bun-served artifact with hot-reload, click-to-annotate, JSON export feedback loop |
| "channels", "channel", "bidirectional", "connected to claude", "send back automatically", "dashboard I can chat with" | **Level 3 — Channel** | Claude Code channel plugin — comments push directly to Claude, Claude updates artifact via tool calls |

Default to Level 1 if ambiguous. Suggest upgrading when it would clearly benefit the task.

---

## Level 1 — Static Artifacts

Generate a single HTML file the user opens in the browser. No server, no dependencies, no build step. This is for "I'll know it when I see it" exploration.

### Use cases

- **Design variations** — show N variations of a UI component side-by-side, numbered. The user picks one (or mixes: "I like #3 but with the header from #7").
- **Presentation slides** — generate slide variations where user picks favorites, then finalize. Include a click-to-select mechanism: clicking a slide marks it as chosen, and a "Copy selections" button exports the picks.
- **Content previews** — show what a LinkedIn post, email, or page looks like in its target platform's visual style.
- **Concept explainers** — interactive walkthrough of a technical concept (tabs, accordions, toggleable detail levels, diagrams, animations). Great for understanding things like row-level security, PgBouncer, connection pooling.
- **Data visualization** — one-shot charts, diagrams, flows.

### How to build

1. Read the codebase to extract the relevant component/content/concept and the project's design language (colors, fonts, spacing)
2. Generate a standalone HTML file — all CSS/JS inline, no external dependencies
3. For variations: each in its own numbered section, meaningfully distinct (not minor tweaks)
4. For >10 variations: use tabs or pagination, not one long scroll
5. Open the file in the browser immediately
6. When user picks a winner, offer to integrate it back into the actual codebase

### Key behaviors

- Match the project's visual language — extract design tokens from the codebase
- Number everything so the user can reference by number
- For design work: include both light and dark variants if the project supports themes
- For presentations: add click-to-select + copy mechanism so the user can pick slides and hand the list back
- Don't over-engineer. A static HTML file with inline CSS is all you need. Speed is the point.

---

## Level 2 — Interactive Artifacts

Serve the artifact via Bun with hot-reload and a click-to-annotate feedback system. The user leaves visual comments, copies them as JSON, pastes back into Claude, Claude updates the file, Bun hot-reloads.

### When to use

The user wants to iterate visually — clicking on areas, leaving comments, and having changes reflected without starting over. The manual copy-paste loop is the key differentiator from Level 3.

### Architecture

```
[Browser]  ←── Bun HTTP + WebSocket ──→  [Bun server]  ←── file watch ──→  [HTML artifact on disk]
                                                                                    ↑
                                                                              [Claude edits file]
```

1. **Bun HTTP server** — serves the HTML artifact with WebSocket hot-reload
2. **Annotation overlay** — pin mode toggle, click anywhere to place a numbered comment bubble
3. **Export mechanism** — "Export Feedback" button copies all annotations as structured JSON to clipboard
4. **Feedback loop:** user pastes JSON → Claude modifies HTML → Bun detects change → WebSocket pushes reload

### How to build

1. Create a project directory for the artifact
2. Write a `server.ts` Bun file that:
   - Serves the HTML file
   - Watches it for changes via `Bun.file().watch()` or `fs.watch()`
   - Pushes reload events over WebSocket
3. Write the HTML artifact with an annotation layer:
   - **Pin mode toggle** (top-right button, Esc to exit) — pins only drop while pin mode is on
   - Click anywhere in pin mode → place a numbered pin with a comment textarea
   - Each pin stores: position (x, y), nearest element selector/id, comment text
   - "Export Feedback" button in a fixed toolbar → serializes all annotations as JSON to clipboard
4. Start the server: `bun run server.ts`
5. Open the browser to the served URL
6. Tell the user: "Toggle Pin Mode on, leave comments, click Export Feedback, then paste the JSON back here"
7. When user pastes feedback JSON: parse annotations, update the HTML file, Bun hot-reloads automatically

### Annotation JSON format

```json
[
  {"id": 1, "x": 340, "y": 120, "target": "#variation-3 .header", "comment": "Make this bigger"},
  {"id": 2, "x": 600, "y": 400, "target": "#variation-5", "comment": "I like this layout best"}
]
```

### Key behaviors

- Keep Bun server minimal — serve + hot-reload only
- Pin mode OFF by default. First-time users will click and nothing happens — mention the toggle explicitly.
- Annotation overlay must not interfere with normal artifact interaction when pin mode is off
- Store pin positions relative to target elements (selector or percentage), not absolute pixels — survives resize
- After receiving feedback, update HTML in-place so Bun hot-reloads automatically
- Debounce file watcher to avoid rapid reloads when writing

---

## Level 3 — Channel Artifacts

Connect the artifact to Claude Code via the Channels feature. Comments push directly to Claude without manual copy-paste. Claude responds via tool calls, and the artifact updates live over WebSocket.

### When to use

Deep data exploration, iterative prototyping, or any workflow where the manual export→paste loop from Level 2 creates too much friction. Especially powerful when combined with MCP servers for live data queries (PostHog, Stripe, databases, etc.).

### Architecture

```
[Browser]  ←── HTTP + WebSocket ──→  [Bun server]  ←── stdio MCP ──→  [Claude Code session]
   ↑                                      │                                  │
   │                                      │ notifications/claude/channel     │
   │                                      ├── (push: comment + meta) ──────→│
   │                                      │                                  │
   │                                      │←── tool calls (mark_addressed,  │
   │                                      │    update_node, update_data) ───│
   │                                      ↓
   │                              [data.json + comments.json on disk]
   │                                      │
   └──── live refresh via WebSocket ──────┘
```

Single Bun process = HTTP server + WebSocket broadcaster + MCP stdio server. The plumbing is fully generic — only the viz, data shape, and MCP instructions change per artifact.

### Step 0: Interview the user

Before scaffolding, ask these questions. Don't proceed without answers (or sensible defaults called out explicitly):

1. **What does the artifact show?** Dashboard, graph editor, kanban board, timeline, map, image annotator, data viz?
2. **Where does the data come from?** MCP server (PostHog, Stripe, GitHub, etc.)? Local file? Generated on the fly?
3. **What are the commentable "nodes"?** Funnel steps, graph vertices, kanban cards, image regions? (Freeform pins anywhere on page are always enabled.)
4. **What should Claude do when a comment arrives?** Query more data? Modify the artifact? Write a natural-language reply? All of the above?
5. **Where should the plugin live?** Default: `tools/<plugin-name>/` in current project. Alt: `~/tools/<plugin-name>/` for user-level.
6. **Plugin name?** Kebab-case. Becomes the MCP server name and channel source.
7. **Sensitive data to redact?** Revenue, PII, API keys → blur or omit.

If user says "just vibe with me", pick sensible defaults and state them.

### Step 1: Scaffold from templates

Create this layout using the bundled templates in `assets/`:

```
<plugin-name>/
├── .claude-plugin/plugin.json    ← assets/plugin.json.template
├── .mcp.json                     ← assets/mcp.json.template
├── package.json                  ← assets/package.json.template
├── server.ts                     ← assets/server.ts.template
├── index.html                    ← assets/index.html.template
├── data.json                     ← assets/data.json.template
└── comments.json                 ← assets/comments.json.template
```

Replace these placeholders in ALL template files:
- `__PLUGIN_NAME__` → kebab-case name (e.g., `customer-journey`)
- `__PLUGIN_NAME_UPPER__` → SCREAMING_SNAKE (e.g., `CUSTOMER_JOURNEY`)
- `__PORT__` → pick an unused port (default range: 5100–5199)
- `__TITLE__` → human-readable title for the artifact
- `__DESCRIPTION__` → one-line description

Run `bun install` in the plugin directory.

### Step 2: Build the visualization

The template `index.html` is a blank canvas with all comment/pin plumbing wired. Implement `window.renderArtifact(DATA)` to paint `DATA` into `#content`.

Every commentable element gets `data-node-id="<your-id>"`. Elements without `data-node-id` are still commentable via freeform pins (auto-anchors to nearest `[data-node-id]` ancestor).

Use ESM CDN imports for libraries — no npm, no bundler:
- **D3 v7** for data viz (sankey, force, scale, shape)
- **Chart.js / Plotly / ApexCharts** for declarative charts
- **Cytoscape.js** for network/graph editors
- **Leaflet** for maps
- **Konva.js** for interactive 2D canvas
- Plain CSS or Tailwind CDN JIT for styling

### Step 3: Shape data.json

Whatever your viz needs. Common patterns:

```json
// Funnel/dashboard
{ "nodes": [{"id": "...", "label": "...", "count": 123}], "edges": [...] }

// Graph/network
{ "nodes": [{"id": "n1", "label": "A", "x": 100, "y": 50}], "links": [...] }

// Kanban
{ "columns": [{"id": "todo", "title": "Todo", "cards": [...]}] }
```

The `update_node` tool in server.ts walks `data.funnel` and `data.sideEvents` by default — generalize the lookup if your shape differs.

### Step 4: Customize MCP tools and instructions

The template provides 3 tools:
- `mark_addressed(comment_id, response)` — mark a pin as addressed with Claude's reply
- `update_node(node_id, patch)` — patch a single data node
- `update_data(data)` — replace entire data.json

Add domain-specific tools as needed (e.g., `add_card`, `move_card` for kanban). Update the `instructions` field in `server.ts` to tell Claude how to interpret comments for this specific artifact.

### Step 5: Register and hand off

Add to project's `.mcp.json`:
```json
{
  "mcpServers": {
    "<plugin-name>": {
      "command": "bun",
      "args": ["run", "--cwd", "<absolute-path-to-plugin-dir>", "--silent", "start"]
    }
  }
}
```

**Give the user this launch block with REAL values (no placeholders):**

```
⚠️ The current session CANNOT receive channel events — you must spawn a new one.

1. Stop anything on port <PORT>:
     kill $(lsof -ti:<PORT>) 2>/dev/null

2. Launch a NEW Claude Code session with the channel:
     claude --dangerously-load-development-channels server:<plugin-name>

   Optional: --dangerously-skip-permissions for auto-approved tool calls.

3. Open http://localhost:<PORT> in your browser.

4. Toggle "Pin mode: on" (top-right) → click anywhere → type → Submit.
   Each pin pushes to Claude instantly. Claude responds via mark_addressed;
   the pin turns green; the reply renders beneath.

To verify: /mcp should show <plugin-name> · ✔ connected
```

**Critical reminders to state plainly:**
- The current session CANNOT receive channel events. A new terminal is not optional.
- Tell the user the actual URL with the real port.
- Pin Mode is OFF by default. Mention the toggle explicitly.

### Converting an existing Level 2 artifact to Level 3

If the user already has an interactive artifact (Level 2) and wants to upgrade:
1. Scaffold the channel plugin (server.ts, plugin.json, package.json, etc.)
2. Replace the Export-to-JSON mechanism with the channel POST — comments go to `POST /comment` instead of clipboard
3. Wire `window.renderArtifact(DATA)` to the existing viz code
4. Add `data-node-id` attributes to commentable elements
5. The pin overlay and comment panel from the template replace the old annotation system

### The dual-purpose mental model

Every channel artifact serves two purposes simultaneously:
1. **Decision capture UI** — each pin records a decision, observation, or question about the data
2. **Conversational surface** — users edit the tool itself through the same interface ("can you add tabs?", "remove the revenue card")

This makes channel artifacts great prototyping tools: iterate visually until the form factor is right, then formalize into a real application with proper backend routes.

---

## General guidelines

- **Always open the artifact in the browser** after building. Don't write files and report done.
- **Match the project's visual language.** Read the codebase for design tokens, colors, component patterns.
- **Start fast, iterate.** Get something visible quickly, refine from feedback.
- **Artifacts are disposable exploration tools.** Inline styles/scripts fine. Output readability > source readability.
- **When the user picks a winner** from variations, offer to integrate back into the actual codebase.
- **Bun is available.** No install needed for Level 2+.

## Gotchas

- **Don't over-engineer Level 1.** Single HTML file, inline CSS, no build tools. Speed is the point.
- **Pin Mode off by default.** Users will click and nothing happens. Always mention the toggle.
- **Hot-reload WebSocket can conflict with channel WebSocket.** Use different ports or paths for Level 2 hot-reload vs Level 3 channel communication.
- **Bun file watcher can be chatty.** Debounce file change events to avoid rapid reloads.
- **Annotation positioning breaks on resize.** Store relative to target element, not absolute pixels.
- **Channel meta MUST be `Record<string, string>`.** Numbers, nulls, booleans cause Zod validation to throw in Claude's stdio handler, silently killing the transport. Always `String()` everything, drop nullish keys via spread.
- **EADDRINUSE on port.** Wrap `Bun.serve` in try/catch; on EADDRINUSE, log "running stdio-only" and `process.stdin.resume()`. Multiple Claude sessions can share state files.
- **DELETE comment must NOT call deliverChannel.** Otherwise Claude wastes turns answering removed comments.
- **Edits to `server.ts` don't hot-reload.** After editing, `/mcp` reconnect in the channel session — or kill the bun process.
- **d3-sankey 0.12 UMD breaks on d3 v7.** Use ESM imports, spread the frozen namespace. See `references/troubleshooting.md`.
- **CSS variables don't resolve as SVG attribute values.** Use literal hex in `.attr("fill", ...)`.
- **Large variation counts (>10) make HTML unwieldy.** Use tabbed or paginated layout.
- **Browser caching can hide updates.** Add `cache-control: no-store` headers.
- **Channel requires a separate Claude Code session.** The session that built the artifact cannot receive channel events. A new terminal is not optional.

## Files in this skill

- `assets/*.template` — Level 3 scaffold templates (plugin.json, mcp.json, package.json, server.ts, index.html, data.json, comments.json)
- `references/troubleshooting.md` — every failure mode with one-liner fixes
- `references/architecture.md` — why the pattern is shaped this way, when to deviate
