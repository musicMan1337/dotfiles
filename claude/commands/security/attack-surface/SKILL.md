---
name: security:attack-surface
description: Maintain the running eBacon attack-surface inventory (~/eBacon/attacksurface.md). Add or update a system, re-discover stale entries, or show the current map. Scoped to TAGEmployerServices org repos. Read-only against infra; only writes the inventory file. Triggers on, attack surface, attacksurface, update attack surface, add to attack surface, inventory a service, what's our attack surface, security inventory, map our surface, refresh attack surface, /security:attack-surface.
---

# Attack Surface Inventory Maintainer

Maintains the single running inventory of eBacon's deployed attack surface. This skill **curates the file**; the deep, scored, per-system assessment is a separate step (`/security:assess-attack-surface`).

`/setup:package-lockdown` runs change exactly what the Defenses line records (pins, age
gates, scanners, update-bot cooldowns); its Phase 5 sends an update here. Accept those
write-backs as routine `update` operations.

## The file

- **Path:** `/Users/derek/eBacon/attacksurface.md` (this is `THE_FILE` below). It lives **outside every git repo on purpose.**
- **Why outside:** `~/dotfiles` (which hosts this skill) is a **PUBLIC** GitHub repo. This inventory maps production infrastructure and must never land in a public repo, an artifact, or an external service.
- If `THE_FILE` is missing, this skill's `add`/`refresh` can recreate it from the template already at the top of the existing file (header + Legend + At-a-glance + Systems + Vendor + Perimeter + Cadence + Assessment log + Backlog + maintenance sections). Preserve that structure.

## Hard rules (authority boundaries)

1. **Never write `THE_FILE` into any git repo, artifact, paste, or external AI service.** It stays at the path above.
2. **Never record secret values** (tokens, keys, passwords, connection strings with credentials). Record only the *name* and *location* of a secret (e.g. "`<SERVICE>_AUTH_TOKEN` in `.env`", "init/unseal key file on the host, mode 600"). If discovery surfaces a live-looking secret, note its existence and location so it can be rotated, and say so in your report, but do not copy the value anywhere.
3. **Read-only against infrastructure.** Discovery reads repo metadata and config; it never deploys, restarts, scans live hosts, or changes anything. It does not run DAST or hit live endpoints. (That is the assess workflow's job, and only with explicit scope.)
4. **Scope = the `TAGEmployerServices` GitHub org.** A repo qualifies only if its `git remote get-url origin` points at `TAGEmployerServices`/`tagemployerservices`. Personal repos that merely live under `~/eBacon` (no origin, or a different owner) are out of scope. Verify origin before inventorying anything new.

## Operations

Dispatch on the argument. If none, default to `status`.

### `status` (default): show the current map
Read `THE_FILE`, print the At-a-glance table plus anything overdue: any system whose Last-assessed + its Cadence is in the past (or "never"), and the top of the findings backlog. Terse. Do not re-run discovery.

### `add <repo>`: inventory a new system
1. Resolve the repo path under `~/eBacon/` and confirm its origin is in the TAG org (rule 4). If it is not, stop and say so.
2. Run scoped discovery (see **Discovery method**) for that one repo.
3. Write a new `### <criticality> <name>` entry following the **Entry template** exactly, inserted in criticality order. Add its row to the At-a-glance table and any new hosts/domains to the Cross-system perimeter table. Assign a seed criticality + cadence per the Cadence model already in the file.
4. Report what you added and any findings (rule 2 applies to secrets).

### `update <system>`: re-discover one existing system
1. Re-run scoped discovery for that system's repo.
2. Rewrite **only that system's entry** and its At-a-glance row. Diff against the old entry and call out what changed (new endpoint, new secret location, changed exposure, new dependency). Never rewrite unrelated entries.
3. Leave the Assessment Log alone (that is the assess workflow's surface).

### `refresh`: re-discover stale entries
Re-run discovery for every system, or only those not touched since a date the user gives. Batch by the **Discovery method**'s concurrency rules. Rewrite each entry in place; summarize the diff per system. This is the periodic "has anything drifted" pass.

### `sync-tables`: repair consistency
No discovery. Just reconcile the At-a-glance table, the perimeter table, and the per-system entries so they agree (e.g. after manual edits). Report mismatches fixed.

## Discovery method

Discovery extracts deployment/security facts from **repo metadata only**: never a full source-tree read. The signal lives in:
`README*`, `package.json` / `composer.json` / `*.csproj`, `Dockerfile`, `docker-compose*`, `.env.example`, `appsettings*.json`, `web.config`, `*.ini`, `.github/workflows/*`, `action.yml`, `cloudbuild.yaml` / `app.yaml` / OpenAPI gateway specs, `terraform/*.tf`, `scripts/*`, `policies/*.hcl`, `CODEOWNERS`.

Delegate the reading to subagents so their bulky output never enters this session; you keep only the structured result and do the file edit.

- **Agent choice:** `classifier` (Sonnet) for the read-and-extract fan-out; it judges type/exposure/criticality well and is cheap. Use `reader` (Haiku) only for a single pure "does file X exist / grep for Y" lookup.
- **Concurrency:** at most **3 concurrent** discovery agents (well under the 4/session, 6/machine CryptoGuard cap; this skill may run while other sessions are active). For a full `refresh`, cluster the systems into <=3 groups and give each agent a **batch** of repos in one prompt (one aggregate `rg`/read pass per repo), rather than one agent per repo. Never have agents write scratchpad temp files; they return the structured entry in their final message.
- **Extraction contract (per system):** the agent returns exactly the fields in the Entry template, writing `unknown/verify` for anything not found in-repo, and **never guessing a value**. It also returns any hardcoded hosts/IPs/domains/URLs (these define the perimeter) and the well-known platform risks for that tech stack (general knowledge is fine there).
- Frame discovery agents as **authorized defensive inventory of the user's own org** so the task reads as the security hygiene it is.

## Entry template (single source of truth for structure)

Every system entry uses these fields, in this order. Match the existing entries' formatting.

```
### <🔴|🟠|🟡|🟢> <Name> `<type>` [`<type2>`]
- **Repo:** `TAGEmployerServices/<repo>` (`~/eBacon/<repo>`)
- **Hosting:** self-hosted (where) | third-party (provider + deploy target)
- **Tech:** languages / frameworks / runtimes + notable deps + versions
- **AuthN (into it):** how a client/user authenticates (cite the file)
- **Exposure:** PUBLIC | INTERNAL | VPN | LOCALHOST | TOKEN | OAUTH | GH-SCOPED (+ audience/evidence)
- **Defenses:** security mechanisms present (cite evidence)
- **Deployed / assets:** endpoints, subdomains, DB connections, integrations, who calls it
- **Secrets surface:** where secrets live (NAMES/PATHS only, never values)
- **Common platform risks:** known issues/misconfigs for this stack
- **Open findings:** real gaps found (bulleted)
- **Criticality:** 🔴/🟠/🟡/🟢 + one-line rationale. **Cadence:** <freq> + continuous controls
```

**Type** = `web` `api` `db` `infra` `auth` `ci` `client` `lib`. **Criticality:** 🔴 Critical (customer PII / payroll / secrets backbone / auth) · 🟠 High · 🟡 Medium · 🟢 Low. Exposure tags are defined in the file's Legend.

## Interplay

- Feeds `/security:assess-attack-surface`: that workflow reads `THE_FILE` to pick targets and writes the Assessment Log + updated Cadence back. This skill owns everything *except* the Assessment Log.
- Complements `ebacon:checklist` (daily health) and `vuln:scan` (dependency CVEs). Cross-reference rather than duplicate: if a system already has a continuous control there, note it in Cadence instead of re-describing it.
