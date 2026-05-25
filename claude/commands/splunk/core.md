---
name: splunk:core
description: Fetch Core API logs (GCP Cloud Run → Splunk HEC sink) from Splunk. Triggers on: core logs, core api logs, coreapi logs, core errors, gcp logs, cloud run logs, trace through core
model: haiku
allowed-tools: mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query, ToolSearch
---

## What "Core" is here

Core = the eBacon Core API, a .NET service running on **Cloud Run** in GCP project `coreapi-393418`. Logs are emitted via Serilog to stdout, picked up by a GCP→Splunk HEC sink, and land in Splunk as JSON.

## Where the logs live

| field            | value                                                             |
|------------------|-------------------------------------------------------------------|
| `index`          | `gcp_app_log`                                                     |
| `sourcetype`     | `gcp_sink_coreAPI` — **Core application logs** (Serilog JSON)     |
| `sourcetype`     | `gcp_service_logs` — cross-service GCP platform notifications (less useful for core debugging) |
| `host`           | `100.20.104.124` (the HEC ingester — **not** the real source; see gotcha #6) |
| `source` (core)  | `coreapi-393418:core-stdout:core-stdout-sub`                      |

Volume: ~3.2k events/day on `gcp_sink_coreAPI`. Recent 7d HTTP status mix: ~3k 200s, ~2.7k 204s, ~20× 429, ~4× 500. Errors are genuinely rare.

## The canonical base search

```spl
index=gcp_app_log sourcetype=gcp_sink_coreAPI
```

## Tool to use

Call `mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query` (load via `ToolSearch` first if not in scope). Skip `get_context` / metadata probing — that information is right here.

## Field structure (Serilog → jsonPayload)

Core logs are nested inside `jsonPayload`. Splunk auto-spath's most of these; if a field returns empty, prefix with `| spath`.

**Serilog control fields:**
- `jsonPayload.@t` — ISO timestamp from the app
- `jsonPayload.@l` — log level: `Information`, `Warning`, `Error` (string — see gotcha #2)
- `jsonPayload.@mt` — Serilog message template
- `jsonPayload.@tr` — distributed **trace ID** (32-hex) — use this to follow a request across services
- `jsonPayload.@sp` — span ID
- `jsonPayload.@x` — full exception text + stack trace (present only on errors)

**HTTP request fields (on request-completion events):**
- `Duration` — ms
- `StatusCode` — HTTP status (int)
- `Endpoint`, `RequestPath`, `RequestName`
- `RequestId`, `TraceId`, `SourceIp`, `ForwardedFor`, `UserAgent`

**Cloud Run metadata:**
- `resource.type` = `cloud_run_revision`
- `resource.labels.service_name` — the actual GCP service emitting the log
- `resource.labels.revision_name` — useful for isolating one deploy
- `labels.commit-sha`, `labels.gcb-build-id` — CI provenance

## Common questions → queries

**Recent errors:**
```spl
index=gcp_app_log sourcetype=gcp_sink_coreAPI "jsonPayload.@l"=Error earliest=-24h
| table _time, Endpoint, jsonPayload.@mt, jsonPayload.@x
```

**5xx responses with stack trace:**
```spl
index=gcp_app_log sourcetype=gcp_sink_coreAPI StatusCode>=500 earliest=-24h
| table _time, Endpoint, StatusCode, Duration, TraceId, jsonPayload.@x
```

**Follow one request across logs (paste the trace id you have):**
```spl
index=gcp_app_log "<trace-id-hex>" earliest=-24h | sort _time
```

**Latency outliers by endpoint:**
```spl
index=gcp_app_log sourcetype=gcp_sink_coreAPI Duration>2000 earliest=-24h
| stats count, avg(Duration) as avg_ms, max(Duration) as max_ms by Endpoint
| sort -max_ms
```

**Per-endpoint traffic + p95:**
```spl
index=gcp_app_log sourcetype=gcp_sink_coreAPI earliest=-24h
| stats count, p50(Duration) as p50, p95(Duration) as p95 by Endpoint
| sort -count
```

**Rate-limited callers (429s):**
```spl
index=gcp_app_log sourcetype=gcp_sink_coreAPI StatusCode=429 earliest=-24h
| stats count by SourceIp, Endpoint | sort -count
```

**Which revision is live and how is it doing:**
```spl
index=gcp_app_log sourcetype=gcp_sink_coreAPI earliest=-1h
| stats count, count(eval(StatusCode>=500)) as errors by resource.labels.revision_name
```

## Gotchas

1. **30–60s ingestion lag.** GCP→HEC isn't instant. `latest=now` may miss the freshest events; if a deploy was seconds ago, wait a minute or pull again. `receiveTimestamp` ≠ `timestamp` — `timestamp` (and `_time`) is the actual event time.

2. **Severity is a string, not a number.** Use `jsonPayload.@l=Error` (exact match). Comparison-style filters like `severity>2` will silently fail.

3. **`@l=Error` vs `@x`.** Some warnings include an exception (`@x`) but log at level `Warning`. To catch "anything with a stack trace," use `jsonPayload.@x=*` instead of relying on level.

4. **`gcp_service_logs` is mostly noise for core debugging.** It carries cross-service platform notifications and includes deliberate test data from `rapidpay` (messages containing "fake error for testing"). For core API issues, stick to `gcp_sink_coreAPI`.

5. **`SourceIp` is partially redacted.** The real client IP is the first hop in `ForwardedFor`; `SourceIp` shows `76.9********`-style masking. Use `ForwardedFor` when you actually need the caller.

6. **`host` is misleading.** All events carry `host=100.20.104.124` (the HEC ingester). The real service is in `resource.labels.service_name`. Never bucket "which service?" by `host`.

7. **Trace IDs span systems.** A `@tr` from core is the same trace ID propagated from upstream Viper / clients (if the caller participates). Free-text search for the hex string across all of `gcp_app_log` to follow it across services and revisions.
