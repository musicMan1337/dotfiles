---
name: vuln:setup
description: One-time bootstrap for vulnerability scanning. Clones every non-archived tagemployerservices repo into ~/eBacon/vuln/ and seeds install-map.json. Triggers on: vuln setup, bootstrap vuln scanning, init vuln, clone all org repos, set up osv scanning.
model: haiku
allowed-tools: Bash
---

Idempotent bootstrap. Safe to re-run — surfaces newly-added org repos and skips already-cloned ones.

Run the setup script:

!`bash ~/.claude/commands/vuln/lib/setup.sh`

When it finishes, report to the user:
- How many repos were cloned this run (vs. already present)
- Any repos missing from `install-map.json` — the script prints these; relay them
- Next step: edit `~/eBacon/vuln/install-map.json` to add install commands for any unmapped repos, then run `/vuln:scan`

## Gotchas

- Requires `gh` CLI authenticated against `tagemployerservices` org. If `gh auth status` fails, tell the user to fix auth first.
- Requires `osv-scanner` and `jq` on PATH. Both should be `brew install`-able if missing.
- The install-map is the user's responsibility — the script can't guess install commands per repo (some monorepos need `pnpm -r install`, some Go services need `make deps`, etc.). Don't try to auto-fill it.
- New repos added to the org later: re-running `/vuln:setup` clones them and flags them as missing from the install-map.
