---
name: splunk:viper
description: Fetch Viper / IIS access logs from Splunk. Triggers on: viper logs, IIS logs, NewViper logs, web access logs, viper requests, viper 5xx, viper slow requests
model: haiku
allowed-tools: mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query, ToolSearch
---

## What "Viper" is here

Viper = the eBacon HR/payroll web app, hosted on IIS on a single Windows host called `NewViper`. The only Viper data shipped to Splunk is the W3SVC IIS access log — there are no PHP application logs, error logs, or stdout logs in Splunk for this app. If you need PHP-level errors, those live on the host's filesystem, not here.

## Where the logs live

| field        | value                                            |
|--------------|--------------------------------------------------|
| `index`      | `file_logs`                                      |
| `sourcetype` | `ms:iis:default:85`                              |
| `source`     | `C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log`      |
| `host`       | `NewViper`                                       |

Volume: ~1.85M events/day, ~1.3k/sec. Status spread is 94.8% 200, 2.3% 304, 1.2% 302, <0.1% 4xx, <0.05% 5xx. 7-day window will cover roughly 13M events on this host.

## The canonical base search

```spl
index=file_logs host=NewViper sourcetype="ms:iis:default:85"
```

## Tool to use

Call `mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query` (load via `ToolSearch` first if not in scope). Skip `get_context` / metadata probing — that information is right here.

## Auto-extracted fields

These are all surfaced without `spath` / `rex`:

- `cs_method` — HTTP verb (`GET`, `POST`, …)
- `cs_uri_stem` — request path (e.g. `/index.php/rest/komodoREST/BenefitGetClientPlans`)
- `cs_uri_query` — full query string
- `sc_status` — HTTP status (see gotcha #1 about type)
- `sc_substatus` — IIS sub-status
- `sc_win32_status` — Win32 error code (`0` = no OS-level error; does **not** imply HTTP 2xx)
- `time_taken` — response time in **milliseconds**
- `bytes_in`, `bytes_out` — request and response body sizes
- `c_ip` — client IP
- `cs_username` — authenticated user (usually `-`)
- `cs_User_Agent_`, `cs_Referer_`, `cs_Cookie_`, `cs_version`
- `s_computername`, `s_sitename`, `s_ip`, `s_port`

**Query string params are also split into individual fields** — e.g. `Client`, `ItemType`, `Event`, `Output`, `Mode`, `LookForward`, `PHPSESSID`. Filter directly on them; do not parse `cs_uri_query` yourself.

## Common questions → queries

**Recent 5xx errors by endpoint:**
```spl
<base> sc_status>=500 earliest=-24h | stats count by cs_uri_stem, sc_status | sort -count
```

**Slow requests (>1s) by endpoint:**
```spl
<base> time_taken>1000 earliest=-24h | stats count, avg(time_taken), p95(time_taken) by cs_uri_stem | sort -count
```

**POST mutations only (skip GET/static asset noise):**
```spl
<base> cs_method=POST earliest=-1h | table _time, cs_uri_stem, sc_status, time_taken, c_ip, cs_username
```

**Status distribution over time:**
```spl
<base> earliest=-24h | timechart count by sc_status
```

**Traffic for one client (by IP or PHPSESSID):**
```spl
<base> (c_ip="<ip>" OR PHPSESSID="<session>") earliest=-24h | sort _time | table _time, cs_method, cs_uri_stem, sc_status, time_taken
```

**Latency percentiles by verb:**
```spl
<base> earliest=-24h | stats p50(time_taken), p95(time_taken), p99(time_taken) by cs_method
```

## Gotchas

1. **`sc_status` may extract as a string.** Numeric comparison like `sc_status>=500` sometimes returns zero. If a result feels too empty, try the OR form `(sc_status=500 OR sc_status=502 OR sc_status=503 OR sc_status=504)` or quote it.

2. **POST bodies are not captured.** Only the URL and query string are logged. For payload-level debugging, you need server-side application logs (not in Splunk).

3. **Static assets dominate volume.** Roughly 60–70% of events are `.js`/`.css`/`.png`/`.svg`/`.woff`/favicon. For app-only views, filter `cs_uri_stem!=*.js cs_uri_stem!=*.css cs_uri_stem!=*.png cs_uri_stem!=*.svg cs_uri_stem!=*.woff cs_uri_stem!=*.ico` or pin to `/index.php/*`.

4. **`sc_status=0` ≠ success.** A literal zero status means the connection was dropped before a response was written (~1.3k/7d). Exclude with `sc_status!=0` when measuring "real" responses.

5. **Time zones don't match.** `_time` is UTC; the timestamp inside the raw log line is local server time (MST). When pasting log lines back at the user, lead with `_time` so there's no ambiguity.

6. **One host, no failover.** All Viper IIS traffic comes from `NewViper`. There is no second app server to compare against if you suspect an instance-local issue — it's the whole production surface.
