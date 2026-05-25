---
name: vuln:fix
description: Triage latest osv-scanner reports and auto-fix simple vulnerabilities (patch/minor bumps of direct deps) by opening PRs in tagemployerservices. Optional positional args narrow scope to specific repos. Defers complex cases for user review. Triggers on: vuln fix, fix vulns, triage vuln reports, open vuln PRs, remediate package vulnerabilities, auto-patch CVEs, fix one repo, fix specific repo.
model: opus
---

You triage the latest scan output, auto-fix the **simple** cases by opening PRs, and surface the **complex** cases for the user to decide on.

## Scope

The user's args follow this paragraph. If non-empty, treat them as a **whitelist of repo names** — case-insensitive match against clone-dir basenames in `~/eBacon/vuln/`. Only triage those repos; ignore everything else. If empty, triage every repo with a non-zero-finding report.

User args: `$ARGUMENTS`

## Inputs (do not re-scan)

- Reports: `~/eBacon/vuln/_reports/<repo>/<latest-timestamp>.json` — use the most recent file per repo
- Clones:  `~/eBacon/vuln/<repo>/`  (scratch working copies — fine to reset/branch freely)
- Install map: `~/eBacon/vuln/install-map.json`

## Simple-fix criteria (per-finding)

A finding qualifies as **simple** when BOTH hold:

1. The affected package is a **direct dependency** of the repo (listed in `package.json`/`go.mod`/`*.csproj`, not transitive-only).
2. osv-scanner provides a fixed version that is a **patch or minor bump** within the same major (`4.17.20 → 4.17.21` ✓; `4.x → 5.x` ✗).

Multiple simple findings within one repo are bundled into **one** branch/PR — every direct-dep patch/minor bump for that repo lands together. Across repos, each repo still gets its own PR.

Findings failing either rule are **deferred** — do NOT attempt to auto-fix:
- Transitive-only fixes that require resolutions/overrides
- Major-version bumps (even when osv lists one as the "fixed" version)
- Findings with no fixed version available
- OS/runtime/base-image CVEs (osv-scanner sometimes reports these)

When in doubt, defer. The user explicitly prefers a clean "deferred" list to a half-broken auto-fix PR.

## Pre-flight research (>3 packages in a single repo bundle)

When a repo's simple-bundle contains **more than 3 packages**, do not jump straight to the fix subagent. First spawn **one Haiku research subagent per package** (parallel, independent). Each researcher:

- Looks up the upstream changelog / release notes between current and target version (npm/Go proxy/NuGet — whatever fits the ecosystem).
- Flags: announced breaking changes, deprecation notices, known regressions, post-release retracts, semver-violating patches.
- Returns: `{pkg, verdict: "safe" | "risky", evidence: "<one-sentence reason>"}`.

After researchers return:
- Packages marked `safe` → stay in the bundle.
- Packages marked `risky` → moved to deferred with the researcher's evidence as the reason.
- If **zero** packages remain safe, skip the repo (everything deferred — note that in the output).
- Then proceed to the fix subagent for the remaining safe set.

Three-or-fewer-package bundles skip research and go straight to fix. The threshold exists because small bundles are easy for a human to eyeball post-merge; large bundles compound risk and deserve a pre-check.

## Workflow

1. **Enumerate** repos with reports. For each, pick the latest `<timestamp>.json` and skip if `vulnerabilities` count is 0.
2. **Classify** every finding. Group simple findings by repo into bundles; collect everything else into `deferred` with a one-line reason.
3. **Dedupe per-repo bundles against existing PRs.** For each repo, run `gh pr list --repo tagemployerservices/<repo> --search "vuln/" --state open --json number,headRefName,title`. If an open PR already covers ANY package in the bundle (match by package name in branch or title), drop that package from the bundle and add it to deferred with reason "existing PR #N (<branch>)". If every package in the bundle is already covered, skip the repo.
4. **Pre-flight research** for any bundle with >3 packages — see the "Pre-flight research" section above. Trim risky packages out of the bundle into deferred before proceeding.
5. **Apply fixes in parallel — one Haiku subagent per repo bundle** (not per package). Subagents are independent across repos; run in parallel. Each subagent:
   - `cd ~/eBacon/vuln/<repo>`
   - Reset to clean default-branch state: `git reset --hard && git clean -fd && git checkout <default> && git pull`
   - Pick a branch name:
     - Single package in bundle: `vuln/<pkg-or-cve>-<YYYYMMDD>`
     - Multiple packages: `vuln/multi-<YYYYMMDD>` (or `vuln/multi-<YYYYMMDD>-N` if collision)
   - Create branch: `git checkout -b <branch>`
   - Edit the manifest(s) to bump every direct dep in the bundle to its fixed version.
   - Run the install command from `install-map.json` once to regenerate the lockfile for all bumps together.
   - Invoke `/git:commit` to commit. **Never commit directly** — global rule requires `/git:commit` for every commit. For multi-package bundles, tell `/git:commit` the scope is a security bump bundle so it produces one combined message.
   - `git push -u origin <branch>`
   - Open PR:
     - Single package: `gh pr create --title "deps: bump <pkg> to <ver> (<CVE/GHSA>)" --body "<body>"`
     - Multi-package: `gh pr create --title "deps: security bumps (<N> packages)" --body "<bulleted list: pkg cur→new (CVE/GHSA) per line>"`
   - Return: `{repo, packages: [...], pr_url}` on success, or `{repo, packages: [...], error}` on failure.
6. **Collect** results, then move any subagent failures into `deferred` with the error as the reason.

## Output

End with these two sections, in this order:

### Opened PRs

| Repo | Packages | Advisories | PR |
|------|----------|------------|----|
| ... | `lodash 4.17.20→4.17.21`, `axios 1.6.0→1.6.7` | GHSA-..., CVE-... | https://github.com/... |

One row per PR (i.e. one per repo). For multi-package PRs, list every bumped package in the Packages cell.

Tell the user: "Pull each branch on your real working copy to test before merging."

### Deferred

| Repo | Package | Severity | Why deferred | Suggested next step |
|------|---------|----------|--------------|---------------------|
| ... | ... | ... | "major bump 4.x → 5.x" | "review changelog, plan migration" |

One row per complex finding. Keep the "why" terse but specific (e.g., "transitive via webpack, needs override" not "complex").

## Gotchas

- **Subagent scope.** Each subagent only needs: the manifest file(s), the lockfile, the report JSON, and the install-map entry. Do not let them read the whole repo — keep them focused and cheap.
- **One subagent per repo, not per package.** Multi-package bundles share one branch, one install run, one PR — bumping deps in series in the same repo would just thrash the lockfile.
- **Research agents are Haiku.** Changelog lookups are pure read tasks; Opus is overkill. Run them in parallel, one per package, only when the bundle exceeds 3 packages.
- **Default branch detection.** Don't hard-code `main`. Use `git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`.
- **Branch name format.** Single-package: `vuln/<pkg-or-CVE>-<YYYYMMDD>`. Multi-package: `vuln/multi-<YYYYMMDD>`. Date suffix prevents collisions on re-fix.
- **PR target = default branch**, not necessarily `main`.
- **Commit channel.** Every commit goes through `/git:commit`. The global rule exists because pre-commit lint hooks need to run; `git commit -m` bypasses them.
- **Don't run `osv-scanner` again.** The reports are already on disk. Re-scanning wastes minutes per repo and can produce different results if upstream advisories shifted between runs.
- **Vuln clones are scratch.** Aggressive `git reset --hard` is correct, not destructive — no human ever edits these clones. (User pulls the *branch* on their real working copy from GitHub for testing.)
- **Lockfile-only is OK as a simple fix.** Some advisories resolve when the direct dep is unchanged but the lockfile re-pins a transitive (e.g., `npm i` after upstream republishes). If the manifest diff is one line or empty and the lockfile diff is bounded, treat as simple.
- **Skip if no advisory.** If a finding has no `fixed` version in any range, it's deferred by definition — there's nothing to bump to.
- **Don't open duplicate PRs.** Always check existing open PRs first (step 3). A stale `vuln/lodash-*` branch from last week's run shouldn't get a sibling today. With multi-package bundles this matters more — if half the bundle is already covered by an open PR, only bundle the uncovered packages.
- **Subagent commit context.** Instruct each subagent to invoke `/git:commit` *after* staging — `/git:commit` handles message generation and the lint gate; the subagent shouldn't draft the message itself.
