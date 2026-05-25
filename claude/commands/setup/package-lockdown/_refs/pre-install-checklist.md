# Pre-install checklist + lock-loop error playbook

Use when adding a single package, or when matching an install/audit error to a documented fix pattern. Source: playbook §6 + §6.5.

## Step 0 (critical): version actually exists in registry

Before pinning any version, confirm it exists in the actual registry. AI-generated audits, research outputs, blog posts, and chat summaries frequently hallucinate or future-date version numbers that do not exist (recommending `pnpm 11.3.0` when real latest is `11.1.3`, or `Node 22.11.0` when active LTS is `24.x`). A non-existent pin appears valid until `pnpm install` / `uv lock` fails. Worse: a hallucinated version that coincidentally exists (typosquat, older yanked release) is a silent supply-chain hazard.

```sh
# npm / pnpm
npm view <pkg> version                                   # latest stable
npm view <pkg> versions --json | tail -20                # recent published
npm view <pkg> time --json | jq 'to_entries | sort_by(.value) | reverse | .[0:5]'

# PyPI
curl -s https://pypi.org/pypi/<pkg>/json | jq -r '.info.version'
curl -s https://pypi.org/pypi/<pkg>/json | jq -r '.releases | keys | sort | .[-10:]'

# crates.io
curl -s https://crates.io/api/v1/crates/<crate> | jq -r '.crate.max_stable_version'

# Go modules
go list -m -versions <module>

# Homebrew
brew info --json=v2 <formula> | jq -r '.formulae[0].versions.stable'

# GitHub releases (Actions, container images, vendor CLIs)
gh release list --repo <owner>/<repo> --limit 10
gh api repos/<owner>/<repo>/releases/latest --jq .tag_name

# Container image tag existence
docker manifest inspect <registry>/<image>:<tag> >/dev/null 2>&1 && echo "exists" || echo "NOT FOUND"

# Node LTS (use this to pick the right Node major)
curl -s https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)] | .[0:5] | .[] | "\(.version) (\(.lts)) \(.date)"'
```

Rules:
1. **No source of truth except the registry.** Documentation, blog posts, LLM output, chat history, prior agent reports are *all* unreliable for exact version numbers. Treat as hints; verify.
2. **If you cannot reproduce a version with one of the commands above, do not pin it.**
3. **Date-stamp the verification.** `# verified YYYY-MM-DD` next to any unusual pin.
4. **Re-verify on lockfile regeneration.** Versions move; a pin that worked six months ago may now be yanked or too old to satisfy a transitive constraint.
5. **For LTS / current-version decisions** (Node, Python, Go, Rust toolchain): always check the official release index, not "what I remember was the LTS." Node LTS rotates yearly; Python minors come out every October.

## The 9-step checklist (after Step 0)

Run before any `pnpm add`, `uv add`, `cargo add`, `go get` of a *new* package. For version bumps of existing packages, Renovate already enforces cooldowns and runs CI scans.

```
1. KNOWN CVES
   OSV: https://osv.dev/list?q=<pkg-name>&ecosystem=<npm|PyPI|crates.io|Go>
   Pass: no critical/high open vulns in current or recent versions

2. BEHAVIORAL ANALYSIS
   Socket.dev: https://socket.dev/<ecosystem>/package/<pkg>
   Pass: no "install scripts," "obfuscated code," "network access," or "malware" flags
   CLI: sfw pnpm add <pkg>   (Socket Firewall intercepts and gates)

3. MAINTAINER HEALTH
   npm: npm view <pkg> maintainers time.modified
   PyPI: pip show <pkg> + PyPI page
   Pass:
   - Last publish < 24 months ago
   - >1 maintainer (mitigates account-takeover blast radius)
   - GitHub repo active, not archived
   - No sudden ownership transfer in last 90 days

4. PACKAGE AGE
   Verify the package itself > 6 months old (not brand-new typo squat)
   npm: npm view <pkg> time.created
   PyPI: PyPI page first upload date
   Pass: package > 6 months old (independent of version cooldown)

5. ADOPTION / DOWNLOADS
   npm: https://npmtrends.com/<pkg>
   PyPI: https://pypistats.org/packages/<pkg>
   Pass: weekly downloads indicate established usage, not a sudden spike

6. PROVENANCE
   npm: npm view <pkg> dist.integrity (sigstore badge on Socket.dev)
   PyPI: curl https://pypi.org/pypi/<pkg>/json | jq '.urls[0].attestations'
   Pass: provenance attestations preferred; sigstore signatures at minimum

7. TYPOSQUATTING
   Verify name matches what the project's own docs/README/website say
   Check name vs popular packages (requests vs request, colors vs color)
   PyPI typosquat tracker: https://pypi.org/security/
   Pass: exact name confirmed from upstream source

8. TRANSITIVE FOOTPRINT
   pnpm: pnpm add <pkg> --dry-run
   uv: uv add <pkg> --dry-run
   Pass: total new transitives < 30 (reject otherwise; reconsider)

9. POSTINSTALL / BUILD SCRIPTS
   npm: npm view <pkg> scripts
   Python: check setup.py / pyproject.toml for build hooks, setup_requires
   Pass: no preinstall/postinstall unless package on known-binary list
   (esbuild, sharp, lightningcss, @biomejs/biome, native @next/swc-*, etc.)
   If postinstall present: add to pnpm.allowBuilds with `pnpm why <pkg>` justification
```

If ALL pass: proceed with `pnpm add` / `uv add`. After install: lockfile + checklist outcome documented in PR description.

For AI agents: require `sfw pnpm add <pkg>` (Socket Firewall wrapper) or refuse if any of steps 1-9 fail.

## Lock-loop error playbook (§6.5)

Match the error to a row. Apply the fix pattern. Don't invent novel responses; the table grows from real bootstrap incidents.

### Trust and supply-chain errors

| Error | Diagnose | Fix |
|---|---|---|
| `ERR_PNPM_TRUST_DOWNGRADE` for `<pkg>@<ver>` | `npm view <pkg> dist-tags` (look for `legacy`, `latest-N`, `next`); `npm view <pkg>@<ver> dist` (compare attestations to a later major). | If parent dep can be bumped to one using the trust-attested major: bump the parent (preferred, structural fix). Otherwise: add `<pkg>: ">=<trust-attested-major>"` to `pnpm-workspace.yaml#overrides` with inline rationale comment. See `case-studies.md` (undici-types, ua-parser-js). |
| `ERR_PNPM_NO_MATURE_MATCHING_VERSION` | Version was published inside the 7-day cooldown (pnpm enforces strictly). | Step back to previous patch. List candidates: `npm view <pkg> versions --json \| tail -10`. Pick the latest one published > 7 days ago. |
| `ERR_PNPM_UNSUPPORTED_ENGINE` | Node binary doesn't match `engines.node`. Either you pinned too-new Node (also failing cooldown) or you haven't installed the pinned Node yet. | If pin inside cooldown, step back to previous LTS patch. If pin correct, install: `fnm use --install-if-missing <X.Y.Z>` (or `nvm install <X.Y.Z>`). |
| `ERR_PNPM_IGNORED_BUILDS` for `<pkg1>, <pkg2>...` | `strictDepBuilds: true` (correct default) is refusing transitives that need postinstall scripts. | For each: `pnpm why <pkg>` to identify parent. Use Step-1 heuristic table in `bootstrap-day-zero.md` to decide allow (`true`) / deny (`false`). Add to `pnpm-workspace.yaml#allowBuilds`. Re-run install. |
| `ERR_PNPM_NO_MATCHING_VERSION` for an override target | Version floor in your override doesn't exist in the registry. Often: advisory listed `Patched at vX.Y.Z` where vX.Y.Z is committed upstream but not yet published. | `npm view <pkg> versions --json \| tail -5` confirms latest published. If advisory's fix isn't published yet: remove override, document as accepted deferred risk. Renovate's `vulnerabilityAlerts.minimumReleaseAge: null` will PR the bump when the version lands. |
| `ERR_PNPM_LOCKFILE_CONFIG_MISMATCH` | You changed `overrides` / `allowBuilds` / `minimumReleaseAge` but haven't re-locked. `--frozen-lockfile` requires lockfile + config to match exactly. | `just lock` then `just bootstrap`. |

### Resolution / compatibility errors

| Error | Diagnose | Fix |
|---|---|---|
| uv `× No solution found when resolving dependencies` | Read the conflict carefully: the message names two specific deps and the constraint that conflicts. Usually a dev-only dep capping a runtime dep, or two satellites disagreeing on an anchor. | Bump the older / more-restrictive dep to a version that loosens the constraint. If neither can move: split into separate dependency groups, or pin the runtime dep to a version both accept. |
| `peerDependencies WARN <pkg>@<ver>` floods (npm/pnpm) | Mostly informational; usually a major-version disagreement across the ecosystem (e.g., React 19 + a package without React 19 peer range yet). | Ignore if `pnpm install` still succeeds. Check: `pnpm peers check`. Only intervene if a runtime import breaks. |
| Advisory reports `Patched at vX.Y.Z` but the bump is blocked by an anchor's range | Framework anchor (next, fastapi, etc.) hasn't updated its declared compat range yet. | (a) Bump anchor to newer version with wider range. (b) If anchor can't move: pin to highest version satisfying anchor and document as accepted risk pending anchor's bump. |
| Major-version cascade after bumping one framework | New framework version requires newer N satellites. | Bump in order: 1) anchor, 2) anchor's typed bindings (`@types/<lib>`), 3) test framework, 4) testing addons. Re-run `just lock` after each layer to catch downstream conflicts early. |

### Tool-flag / invocation errors

| Error | Cause | Fix |
|---|---|---|
| `pip-audit` fails with `SIGABRT` on `ensurepip` (uv-managed Python) | uv's installed Python lacks `ensurepip`; pip-audit's default mode tries to create a sub-venv with pip preinstalled. | `uvx pip-audit --requirement <file> --no-deps --disable-pip --strict`. CI with system Python is unaffected. |
| `osv-scanner: flag provided but not defined: -recursive` (similar) | OSV-Scanner 2.x reorganized commands. Older `osv-scanner --recursive` is gone. | Use `osv-scanner scan source --recursive <dir>`. Check `osv-scanner scan source --help` for current flags. |
| Tool prints "Update available! X -> Y" tempting you to follow | Some CLIs (pnpm self-update, npm-check-updates) bypass cooldown when self-updating. Following blindly fetches a same-day release. | Ignore the prompt. Let Renovate (cooldown-gated) PR the update. Manual update only after version aged > 7 days. |

### Audit findings (not lock failures)

| Finding | Action |
|---|---|
| `pnpm audit` reports `low` / `moderate` and you can override the package | Verify override target exists (`npm view <pkg> versions`); verify equal-or-better trust (`npm view <pkg>@<ver> dist`); add to `overrides`. Re-lock + re-audit. |
| `pnpm audit` reports a vuln but no fix published yet | Document as accepted deferred risk in override block with `# WAITING UPSTREAM PUBLISH` + advisory URL. Renovate watches for the publish. |
| `pip-audit` clean, `osv-scanner` reports more | Expected: scanners have non-overlapping coverage. Trust the union. Investigate each; fix the patchable; document the rest. |
| New `osv-scanner` finding that same scanner missed last week | OSV / GHSA databases continuously update. Run scanners on a schedule (CI cron), not only on lockfile changes. |
| Vuln in a dev-only dep (test framework, build tool) | Lower priority than runtime deps. Patch but urgency closer to "next sprint" than "hotfix." |
| Vuln reachable only via deeply nested transitive chain | Identify shallowest parent you can bump (`pnpm why <pkg>`). Patching at depth 8 via override is brittle; bumping at depth 2 is durable. |
