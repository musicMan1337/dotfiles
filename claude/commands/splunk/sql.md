---
name: splunk:sql
description: Fetch SQL Server logs (MSSQL engine + Agent) from Splunk. Triggers on: sql logs, sqlprod logs, mssql logs, sql failed logins, sql backups, sql deadlocks, sql agent failures
model: haiku
allowed-tools: mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query, ToolSearch
---

## What's in scope

SQL Server logs at eBacon flow through the **Windows Application event log**, not a dedicated MSSQL sourcetype. There is no shipping of the raw `ERRORLOG` text file to Splunk — anything you'd see in SSMS's "SQL Server Logs" node only reaches Splunk if SQL also wrote it to the Application log.

## Where the logs live

| field        | value                                                              |
|--------------|--------------------------------------------------------------------|
| `index`      | `wineventlog`                                                      |
| `sourcetype` | `WinEventLog`                                                      |
| `LogName`    | `Application` (SQL publishes here)                                 |
| `host`       | `SQLPROD19` (prod primary), `SQLPROD19B` (prod secondary), `BSQLDEV` (dev) |

Filter to SQL with one of:

- `ProviderName="MSSQLSERVER"` — engine events (login auditing, backup, deadlock, errors)
- `ProviderName="MSSQLSERVERAGENT"` — Agent / job logs (currently sparse; see gotcha #4)

Typical 24h volume: SQLPROD19 ~633k events total, SQLPROD19B ~324k, BSQLDEV ~116k. Most of that is **not** SQL — see gotcha #2.

## The canonical base search

```spl
index=wineventlog host=SQLPROD19 ProviderName="MSSQLSERVER"
```

Drop the `host=` clause to span all three; add `LevelDisplayName=Error` to narrow to errors only (rare — see gotcha #3).

## Tool to use

Call `mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query` (load via `ToolSearch` first if not in scope). Skip `get_context` / metadata probing — that information is right here.

## Auto-extracted fields

- `EventCode` — SQL-specific numeric code (see codes table below)
- `ProviderName` — `MSSQLSERVER` or `MSSQLSERVERAGENT`
- `LevelDisplayName` — `Information`, `Warning`, `Error`
- `TaskDisplayName` — category (`Logon`, `Backup`, `Server`, …)
- `MachineName` — FQDN (`SQLPROD19.tagbiodome.com`)
- `message` — full event text, **multiline**, contains the interesting parts (database name, backup path, client IP, etc.)
- `LogName` — `Application`

## Useful EventCodes

| Code        | Meaning                                                  |
|-------------|----------------------------------------------------------|
| 18453       | Login succeeded (engine)                                 |
| 18456       | Login failed (engine) — **not currently observed** in prod, see gotcha #5 |
| 4625        | Windows-level account logon failure (still useful for sa-via-AD attempts) |
| 1205        | Deadlock victim chosen                                   |
| 18265       | Log backup completed                                     |
| 18270       | Database backup completed                                |
| 3014        | Backup/restore completion (alternate)                    |
| 35200-35299 | Always On / HADR replication events                      |
| 5408        | Schema lock event — **64% of SQLPROD19 volume, near-pure noise; exclude** |

## Common questions → queries

**Recent failed logins:**
```spl
index=wineventlog host=SQLPROD19 (EventCode=18456 OR EventCode=4625) earliest=-24h | table _time, EventCode, message
```

**Backups in the last 24h:**
```spl
index=wineventlog host=SQLPROD19 ProviderName=MSSQLSERVER (EventCode=18265 OR EventCode=18270 OR EventCode=3014) earliest=-24h
| rex field=message "Database: (?<db>[^,]+)"
| stats count, max(_time) as last_backup by db, EventCode
| eval last_backup=strftime(last_backup, "%Y-%m-%d %H:%M:%S")
```

**Deadlocks (any host) in the last 7d:**
```spl
index=wineventlog ProviderName=MSSQLSERVER EventCode=1205 earliest=-7d | table _time, host, message
```

**SQL Agent job failures:**
```spl
index=wineventlog ProviderName=MSSQLSERVERAGENT LevelDisplayName=Error earliest=-24h | table _time, host, EventCode, message
```

**Always On replication health:**
```spl
index=wineventlog host=SQLPROD19 ProviderName=MSSQLSERVER EventCode>=35000 EventCode<36000 earliest=-24h | stats count by EventCode, LevelDisplayName
```

**Any SQL errors (broad sweep):**
```spl
index=wineventlog ProviderName=MSSQLSERVER LevelDisplayName=Error earliest=-24h | table _time, host, EventCode, TaskDisplayName, message
```

## Gotchas

1. **No raw ERRORLOG in Splunk.** If a SQL Server error never gets routed to the Windows Application log (some internal warnings don't), Splunk will not have it. Suggest checking the host's `ERRORLOG` file directly when a problem is suspected but Splunk is silent.

2. **`wineventlog` index is mostly *not* SQL.** Without `ProviderName="MSSQLSERVER"`, you'll see logon auditing, security group management, group policy, and `EventCode=5408` flooding everything. Always anchor on `ProviderName` for SQL questions.

3. **`LevelDisplayName=Error` is rare.** Most engine events are `Information` (logins, backups, lifecycle). Filtering to `Error` will often produce zero rows — that doesn't mean SQL is healthy, just quiet at the event-log level.

4. **Agent events may be missing.** `ProviderName="MSSQLSERVERAGENT"` was not observed in recent samples — SQL Agent may not be configured to write to the Application log on these hosts. If you need job history, querying `msdb.dbo.sysjobhistory` directly is more reliable.

5. **SQL login auditing (18456) appears off in prod.** Engine-level failed logins (`EventCode=18456`) were absent from recent samples — only Windows-level `4625` events were present. Don't tell the user "no failed logins" if 18456 is absent; tell them auditing is likely not configured at the engine level.

6. **Messages are multiline.** Database names, backup paths, and client IPs sit inside the `message` field, often after labels like `Database:` or `[CLIENT:`. Use `rex field=message "..."` to extract — `spath` won't help (it's not JSON).

7. **SQLPROD19B = secondary.** Its event mix is replication-heavy and skewed away from user-driven traffic. For "what did production do," prefer `host=SQLPROD19`; include B only when investigating replication/failover.
