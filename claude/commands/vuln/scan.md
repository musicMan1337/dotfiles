---
name: vuln:scan
description: Run osv-scanner across cloned eBacon repos. Pulls latest, installs deps from install-map, resets, scans, writes per-repo JSON reports. Optional positional args narrow scope to specific repos. Triggers on: vuln scan, scan vulns, run osv, scan all repos for vulnerabilities, check package vulns, run vuln pipeline, scan one repo, scan specific repo.
model: haiku
allowed-tools: Bash
---

Pull/install/scan repos in `~/eBacon/vuln/`. Per-repo JSON reports land in `~/eBacon/vuln/_reports/<repo>/<timestamp>.json`.

**Scope:** with no args, every cloned repo is scanned. Pass repo names as positional args to narrow scope — e.g. `/vuln:scan Viper SQL` runs only those two. Matching is case-insensitive against clone directory names.

Run the scan (`$ARGUMENTS` passes through the user's repo-name args):

!`bash ~/.claude/commands/vuln/lib/scan.sh $ARGUMENTS`

When it finishes:
- Relay the printed summary (per-repo vuln count) to the user
- Call out any repos that errored (pull failed, install failed, etc.) — those need manual attention
- Suggest `/vuln:fix` if any repos have non-zero findings; skip the suggestion if all are clean

## Gotchas

- **Repos missing from `install-map.json` are skipped** with a warning. Re-run `/vuln:setup` to surface newly-added repos, then fill in the map.
- **`git reset --hard` after install is intentional.** Vuln clones are scratch — they should never accumulate diffs. The reset prevents lockfile churn from polluting subsequent runs.
- **osv-scanner returns nonzero when findings exist.** That's normal, not a failure. The script handles it.
- **`scan source -r .`** is the current osv-scanner 2.x spelling. Older docs say `osv-scanner -r .` — don't "fix" it.
- **`--no-ignore` is load-bearing, don't drop it.** osv-scanner honors `.gitignore` by default, so a repo that gitignores its own lockfile (AIDeterminations, GenericCron, SFTPService, mPDF, QBOApp all do) scans as if it had no dependencies and reports "no package sources found". That silently hid 64 real findings until 2026-08-04. It does not inflate results: node_modules holds no lockfiles, so the scanned-source count is unchanged.
- **`--allow-no-lockfiles` makes a manifest-free repo exit 0 instead of 128.** Without it, ~19 repos that legitimately have nothing to scan show up as ERROR rows and drown out real failures.
- **The post-install `git reset --hard` must stay AFTER the scan.** It used to run before, which deleted the lockfile `npm install` had just generated, so every repo without a committed lockfile (autoScheduler, nPushService, federalDetermination) scanned nothing.
- **.NET needs `dotnet restore --use-lock-file`.** osv-scanner reads `packages.lock.json`; plain `dotnet restore` only writes `obj/project.assets.json`, which it ignores. Verified on Ruler: 0 findings before, 2 after.
- **Don't run scans in parallel.** Some installs (Go, .NET) compete for global caches and corrupt each other. Serial is fine — full org takes a few minutes.
- **If a repo's default branch is something exotic** (not main/master), the script auto-detects via `git symbolic-ref refs/remotes/origin/HEAD`. If that fails, the repo is reported as errored and skipped.
