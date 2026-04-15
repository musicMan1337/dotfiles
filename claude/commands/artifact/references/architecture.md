# Channel artifact — architecture

Deeper notes on *why* the pattern is shaped this way, and where it's reasonable to deviate.

## Why a channel and not polling

Two earlier designs don't work:

1. **ScheduleWakeup polling.** Poll `comments.json` every ~60s. Dies under latency, burns tokens checking empty file, can't push progress updates back between polls.
2. **Hooks.** `UserPromptSubmit` / `PostToolUse` / `Stop` hooks can't inject new user turns from an external HTTP call — they only fire on Claude actions.

Channels are the only push-based primitive in Claude Code for external systems → live session. Servers declaring `experimental: { 'claude/channel': {} }` capability can emit `notifications/claude/channel` events that Claude surfaces as `<channel source="...">` events in the conversation.

## Why the server owns BOTH MCP stdio and HTTP

One process is simplest. Alternatives considered:

- **Separate bun UI + MCP shim** — more robust but doubles surface area and setup friction.
- **MCP only, UI served elsewhere** — user has to start UI separately. Brittle.

Two failure modes handled explicitly:
1. **Port in use** — catch `EADDRINUSE`, run stdio-only, `process.stdin.resume()`. Tool calls still work via shared state files.
2. **Process exits** — without Bun.serve holding event loop, script reaches EOF. `process.stdin.resume()` prevents that.

## Why JSON files for state

- **Trivially inspectable** — `cat comments.json` is debugging gold.
- **Merge-friendly** — multiple sessions can share files. Not concurrent-write-safe at FS level, but conflicts are rare and detectable.
- **No migration burden** — shape changes are just code changes.

For concurrency/scale, swap to SQLite. API surface doesn't change.

## Why WebSocket + polling fallback

WebSocket is fast path (<100ms from tool call → UI refresh). 30s poll on `/data.json` + `/comments.json` as safety net — if WS dies, UI converges within 30s.

## Why freeform pins + data-node anchoring

Hierarchical model:
1. **Data-node pins** — click element with `data-node-id`. Claude has direct context via `data.json`.
2. **Freeform pins** — click whitespace or untagged element. `nodeId = "freeform"`, `anchorNodeId` = nearest `[data-node-id]` ancestor, `contextSnippet` = 200-char slice of surrounding text.

Preserves position, semantic anchor, AND textual context. Claude uses whichever is most informative.

## Why one-way channel notifications

Claude replies via tool calls (`mark_addressed`, `update_node`, `update_data`), not reverse channel messages:
- Tools have a schema — structured replies
- Tools hit FS directly — UI sees update via WebSocket broadcast on write
- Channel stays a "firehose of user intents" — not a bidirectional chat with persistence concerns

## When to deviate

- **Multi-user / remote** — put bun behind authenticated reverse proxy. State files become shared DB.
- **High-frequency data** — >10 writes/sec, use pub-sub instead of file writes.
- **Large binary assets** — don't base64 in data.json. Serve separately, reference by URL.
- **Visible channel replies** — default is silent tool-call mutations. To add terminal commentary, instruct it in the MCP `instructions` field.
- **Non-funnel data** — keep channel plumbing, swap `render*()` functions and `data.json` shape.

## The cognitive model

User's mental model: "I click → Claude thinks → the page updates."

Every affordance reinforces this:
- Pins persist across page loads and sessions
- Status badge (pending → addressed) gives immediate feedback
- Claude's response renders inline, not in a separate tab
- No refresh button — WebSocket + polling handles updates invisibly
