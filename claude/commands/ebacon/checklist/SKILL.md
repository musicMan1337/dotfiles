---
name: ebacon:checklist
description: Daily ownership checklist for eBacon services Derek owns. Run this every morning to surface degradation before it becomes an incident. Triggers on, daily checks, my checklist, daily check, what should I check today, owner duties, daily maintenance, ebacon checklist, what should I check, morning checks, owner check, anything I need to look at, am I on top of my services.
---

# eBacon Daily Ownership Checklist

You are walking Derek through his daily ownership review for services he owns. The point is to surface degradation early, with low alarm fatigue, not to do work.

## Operating rules

- **Read-only by default.** Run queries, read state, report. Do NOT run remediation, restarts, scans, or any state-changing command unless Derek explicitly asks for it after seeing the report.
- **Splunk-first.** Most of the data lives in the vault-health snapshot stream in Splunk. SSH into the VPS only when something is missing from Splunk and the answer matters.
- **Terse output.** Lead with the verdict per service (🟢/🟡/🔴). One line per flagged check. No preamble, no recap of what you ran. If everything is green, two lines total is enough.
- **Distinguish real signal from known noise.** Several "warnings" in the current pipeline are well-understood (see Gotchas). Do not surface them as alerts.
- **Time matters.** "Latest snapshot was 1.5h ago" is fine. "Latest snapshot was 6h ago" is itself a red flag, the sidecar is broken.

## Active services

| Service | Repo | VPS | Splunk source |
|---|---|---|---|
| Vault (Truffle) | `/Users/derek/eBacon/truffle` | `10.19.1.12` | `/servicesLogs/truffle/vault-health.logg` |

More services will be added as ownership transitions. To add one, see the bottom of this file.

---

## Vault

### Step 1: pull the latest snapshots from Splunk

Use `mcp__plugin_splunk-mcp-plugin_splunk-mcp__splunk_run_query` (load via ToolSearch if not already in scope). One query gets both event types:

```
index=file_logs source="/servicesLogs/truffle/vault-health.logg" | head 2
```

Use `earliest_time=-2h`. The pair you want is the most recent `event=health_snapshot` plus the most recent `event=metrics_snapshot` (they're emitted together).

If the newest event is **>90 minutes old**, that itself is the headline. The sidecar emits hourly, so up to ~60 min staleness is normal; beyond that, something is broken. Report it as 🔴 "vault-health sidecar not emitting" and skip the rest.

### Step 2: read the fields you care about

From `health_snapshot`:
- `overall_status` (`ok` | `warn` | `red`): single alertable field
- `warnings`, `errors`: CSV of check names that flagged
- `version`: deployed Vault version
- `initialized`, `sealed`, `standby`: core state
- `backup_age_hours`, `backup_count_7d`: backup pipeline health
- `cert_server_days`, `cert_ca_days`: PKI runway
- `data_disk_used_pct`, `logs_disk_used_pct`: disk headroom
- `audit_log_age_min`, `audit_log_size_mb`: audit pipeline liveness

From `metrics_snapshot`:
- `unsealed` (0 or 1, should agree with `sealed` inverse from health)
- `lease_count`: active leases
- `alloc_bytes`, `sys_bytes`, `goroutines`: runtime memory profile

### Step 3: check version drift against GitHub releases

Compare the snapshot's `version` against the latest stable release. Single API call, no token needed:

```sh
curl -s https://api.github.com/repos/hashicorp/vault/releases/latest | jq -r '.tag_name'
```

Verdict (semver):
- Same version → 🟢
- Patch bump (`1.18.0` → `1.18.1`) → 🟡 schedule when convenient
- Minor bump (`1.18` → `1.19`) → 🟡 read changelog, schedule
- Major bump (`1.x` → `2.x`) → 🔴 plan migration with a real changelog read; do not just `docker compose pull`

Upgrade procedure lives in `scripts/upgrade-vault.sh --prod`.

### Step 4: check OSV vuln scan freshness

Vuln scanning is a separate skill (`vuln:scan`), not this one's job. Just surface freshness:

```sh
ls -lt ~/eBacon/vuln/truffle/*.json 2>/dev/null | head -1
```

If the newest report is >7 days old (or the directory doesn't exist), flag 🟡 "vuln scan stale, last run N days ago" and suggest `/vuln:scan truffle`. Do not run the scan from inside this checklist.

### Step 5: build the report

Structure:

```
Vault: <emoji> overall <ok|warn|red>
  - [only if flagged] <check name>: <value>
  - [if version drift] <current> deployed, <latest> available (<patch|minor|major>)
  - [if osv stale] vuln scan last run <N> days ago
  - [if snapshot stale] latest snapshot <N> minutes ago
```

If everything is clean: just `Vault: 🟢` and move on. Do not invent things to say.

## Gotchas (real, not actionable, do not alarm)

These are well-understood today and should be ignored unless they meaningfully degrade.

1. **`vault_data_mb: 1` is a measurement artifact, not data loss.** The sidecar bind-mounts `vault/data` read-only and cannot recurse into mode-700 subdirs to measure size accurately. Real data is intact even though this field reads 1. Only treat as a signal if `initialized: false` also shows.

2. **`audit_log_age_min` is high when nobody is actively using Vault.** The audit log is only written when Vault handles a request. During off-hours or low-traffic periods, the file age legitimately grows. Threshold of 360 min flags this; surface only if >24h or coincident with other red signals.

3. **`audit.logg` shipping to Splunk has been broken since 2026-04-16.** The forwarder is tracking a stale inode. This is a separate pre-existing issue, not something this checklist's job to flag every day. Mention once and move on.

4. **TLS handshake errors spamming `vault-server.logg` from `172.26.0.1`.** Host port 7675 maps to container 8201 (mTLS listener). Clients hitting `http://10.19.1.12:7675` get refused. Noise from a misconfigured client, not a Vault problem. Direct host clients at port 6465 (plain HTTP) or `https://...:7675` with the CA cert.

5. **`scripts/rotate-root-token.sh` and `scripts/rekey-unseal.sh` are untested against Vault 2.0.** Vault 2.0 changed `sys/rekey` and `sys/generate-root` to require both a token AND a key fragment. If you need either, test in a non-prod context first. Not a daily-check item, just a known sharp edge.

6. **The vault-health sidecar emits hourly.** A snapshot 50 minutes old is still current. Don't force a manual emit just to refresh the report unless something is on fire.

7. **Vault 2.0 logs `incrementing seal generation, generation:1` on first boot against pre-2.0 data.** Normal, not a problem.

## Splunk query reference

The truffle skill (`splunk:truffle`) has the canonical base search and field paths. Use it for any Vault-related Splunk question outside this checklist (audit log analysis, secret access patterns, etc.). The base search for vault-health specifically:

```
index=file_logs source="/servicesLogs/truffle/vault-health.logg" event=health_snapshot
```

Useful one-liners for follow-up if something is flagged:

| Question | SPL |
|---|---|
| Trend cert expiry over 7 days | `... | timechart span=1d latest(cert_server_days)` |
| Any sealed events in last day | `... earliest=-24h sealed=true` |
| Max disk usage in last 24h | `... | stats max(data_disk_used_pct) max(logs_disk_used_pct)` |
| Lease count growth | `... event=metrics_snapshot | timechart span=1h max(lease_count)` |

## How to add a new service

1. Add a row to the "Active services" table with its repo path and Splunk source.
2. Add a `## <Service>` section below "Vault" with its Steps 1-5 (query Splunk, interpret thresholds, version drift if applicable, freshness checks, build report).
3. Service-specific gotchas go in their own gotchas subsection under that service.
4. When this file exceeds ~250 lines, split per-service content into `references/<service>.md` and shrink the main SKILL.md to an orchestrator that loads each reference on demand.

## What this checklist deliberately does NOT cover (yet)

Defer these to dedicated skills or future expansion of this one:

- Open PRs Derek owns or owes review on (use `obsidian:briefing` or `gh pr list`)
- Vault audit log activity analysis (use `splunk:truffle`)
- Vuln remediation (use `vuln:fix`)
- Multi-service incident detection / on-call signals
- Cost / quota signals from cloud providers
