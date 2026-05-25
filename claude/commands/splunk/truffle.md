---
name: splunk:truffle
description: Fetch Truffle (HashiCorp Vault POC) audit logs from Splunk. Triggers on: truffle logs, vault audit, vault logs, truffle audit, what did truffle do
model: haiku
allowed-tools: mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query, ToolSearch
---

## What "Truffle" is

Truffle = the HashiCorp Vault POC instance (case 331005). Its audit log is shipped to Splunk as JSON events from the `infra` host. Vault hashes every sensitive value before writing the audit record, so anything that looked secret is HMAC-SHA256 in the log.

## Where the logs live

| field        | value                                |
|--------------|--------------------------------------|
| `index`      | `file_logs`                          |
| `sourcetype` | `biodome_service_logs`               |
| `source`     | `/servicesLogs/truffle/audit.logg`   |
| `host`       | `infra`                              |

Note the `.logg` extension — that is the real filename, not a typo to fix in the query.

## The canonical base search

```spl
index=file_logs sourcetype=biodome_service_logs source="/servicesLogs/truffle/audit.logg"
```

Pin the time range explicitly — see gotcha #1.

## Tool to use

Call `mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query` (load via `ToolSearch` first if not in scope). Skip `get_context` / metadata probing — that information is right here.

## Useful field paths (events are JSON)

Vault audit events have these top-level keys: `time`, `type` (`request`|`response`), `auth`, `request`, `response`.

- `request.operation` — `read`, `update`, `create`, `delete`, `list`
- `request.path` — e.g. `secret/data/dev/twilio`, `auth/token/revoke-self`
- `request.remote_address` — caller IP
- `auth.display_name` — e.g. `cert-derek-workstation`
- `auth.policies{}` — applied ACL policies
- `auth.metadata.common_name` — cert CN (e.g. `derek.workstation.truffle.internal`)
- `response.data.data.*` — returned secret payload (all hashed)

Extract with `spath` if fields aren't auto-extracted:

```spl
<base search> | spath | table _time, type, request.operation, request.path, auth.display_name, request.remote_address
```

## Common questions → queries

**Was Truffle accessed today?**
```spl
index=file_logs sourcetype=biodome_service_logs source="/servicesLogs/truffle/audit.logg" earliest=-24h | stats count
```

**Who touched which paths?**
```spl
<base> | spath | stats count by auth.display_name, request.operation, request.path | sort -count
```

**Which secrets were read?**
```spl
<base> type=response request.operation=read request.path=secret/* | spath | stats count by request.path, auth.display_name
```

**Auth token activity (login/revoke/renew):**
```spl
<base> request.path=auth/token/* | spath | table _time, request.path, request.operation, auth.display_name
```

## Gotchas

1. **Default `-24h` window may be empty.** As of 2026-05-13 there is one observed burst of 8,098 events covering **2026-04-16 12:27:33 → 12:41:22 MST** and nothing since — log shipping appears to have stopped. If a query returns zero rows, widen to `earliest=-90d` and tell the user log shipping looks broken rather than reporting "no activity."

2. **No plaintext secrets are recoverable.** Vault hashes every secret value, token, and password before writing the audit record — fields look like `"api-key":"hmac-sha256:8ceb…"`. Do not promise to retrieve a token or password value from these logs; you can only confirm the *path* was accessed and by whom.

3. **`request` and `response` are paired.** Every operation emits two events (`type=request` then `type=response`). For "what happened," filter `type=response` or you double-count. For "what was attempted but denied," compare requests with no matching response or where `policy_results.allowed=false`.

4. **Use the source filter, not just keyword `truffle`.** A free-text `truffle` search also matches cert CNs in *other* sources (and these very logs) and runs slowly. Always anchor with `source="/servicesLogs/truffle/audit.logg"`.

5. **Don't use `index=*`.** Hit `index=file_logs` directly — the truffle source only lives there, and `index=*` scans every index in the cluster.
