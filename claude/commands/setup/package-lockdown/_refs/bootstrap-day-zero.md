# Bootstrap day zero

Use when the repo is NEW (no lockfile, empty/scant manifest, user said "init / scaffold / new project"). Source: playbook §3.5 + §6 Step 0.

Goal: converge in 1-2 lock iterations, not 8. Skipping steps below means re-locking 3-8 times.

## Step 0: Verify meta-tool versions against canonical registries

Never source a version from chat history, prior agent output, blog posts, or general knowledge. LLMs hallucinate plausible-looking versions; the registry is truth.

```sh
# Node Active LTS (NOT Maintenance LTS); pick the most-recent "Active" line
curl -s https://nodejs.org/dist/index.json | \
  jq -r '[.[] | select(.lts != false)] | sort_by(.date) | reverse | .[0:5] | .[] | "\(.version) (\(.lts)) \(.date)"'

# pnpm
npm view pnpm version
npm view pnpm time --json | jq 'to_entries | sort_by(.value) | reverse | .[0:5]'

# uv
curl -s https://pypi.org/pypi/uv/json | jq -r '.info.version'

# python: uv manages its own pythons
uv python list --only-installed
uv python install <X.Y>

# CLI binaries via brew
brew info --json=v2 just biome osv-scanner | jq -r '.formulae[] | "\(.name): \(.versions.stable)"'
```

Apply the cooldown filter to every meta-tool version. A version published 3 days ago fails the `minimumReleaseAge: 7d` rule even if the registry's `latest`. Step back to the most-recent version published more than 7 days ago:

```sh
# Generic "latest past cooldown" check (npm)
npm view <pkg> time --json | jq -r '
  to_entries
  | map(select(.key | test("^[0-9]") and (test("-") | not)))
  | map(select(.value < (now - 7*24*60*60 | todateiso8601)))
  | sort_by(.value)
  | last
  | "\(.key) (\(.value))"
'

# PyPI equivalent
curl -s https://pypi.org/pypi/<pkg>/json | jq -r '
  .releases
  | to_entries
  | map(select(.key | test("[a-z]") | not))
  | map(select(.value[0].upload_time_iso_8601 < (now - 7*24*60*60 | todateiso8601)))
  | sort_by(.value[0].upload_time_iso_8601)
  | last
  | .key
'
```

Cross-check Node against shell. If using fnm/nvm/asdf, confirm the pinned Node is installed before writing `.nvmrc` + `engines.node`. `pnpm install` with `engineStrict: true` refuses to run on a mismatch.

Cooldown-for-the-manager itself is a tradeoff. Two defensible options:
- **Strict:** pin pnpm/uv to the latest version past the cooldown (highest discipline; highest friction; right for regulated / persistent-secret infra).
- **Pragmatic:** pin the manager to whatever your environment has; rely on cooldown to protect the *transitive* dep graph that flows through it (right for product engineering). Document inline so it's an explicit decision, not an accident.

## Step 1: Pre-populate `allowBuilds` with the native-binary baseline

pnpm v11 blocks all postinstall scripts unless explicitly allowed. The packages below run *legitimate* postinstalls to download/install native binaries. Pre-populate to save round-trips:

```yaml
# pnpm-workspace.yaml
allowBuilds:
  # Native compilers (almost any modern frontend stack uses these)
  esbuild: true
  "@biomejs/biome": true
  "@swc/core": true
  lightningcss: true

  # Framework-specific native compilers (add only if you use the framework)
  "@next/swc-darwin-arm64": true
  "@next/swc-darwin-x64": true
  "@next/swc-linux-x64-gnu": true
  "@next/swc-linux-x64-musl": true
  "@next/swc-linux-arm64-gnu": true
  "@next/swc-linux-arm64-musl": true

  # Native image processing
  sharp: true

  # Native crypto / DB bindings (add only if used)
  better-sqlite3: true
  node-gyp: true

  # Code-analysis tooling (add only if you use ast-grep)
  "@ast-grep/lang-go": true
  "@ast-grep/lang-php": true
  "@ast-grep/lang-python": true
  "@ast-grep/lang-ruby": true
  "@ast-grep/lang-rust": true
```

Heuristic for evaluating a new package's postinstall:

| Signal | Decision |
|---|---|
| Postinstall downloads / installs native binary (`.node`, `.so`, `.dylib`) | Allow (`true`). Same category as defaults. |
| Postinstall prints sponsorship / fundraising / advertising banner | Block (`false`). Package functions without it. |
| Postinstall runs analytics / telemetry / phone-home | **Block** (`false`). Often a signal to reconsider the package entirely. |
| Postinstall does uncommon shell, network calls, file writes outside its own dir | **Block + investigate.** Possible malicious payload. Audit before adding. |

Inspection commands:
```sh
npm view <pkg> scripts
npm view <pkg>@<ver> dist.tarball
tar -xzOf <tarball> package/postinstall.js | head -50
```

## Step 2: Compute the framework compatibility chain BEFORE pinning satellites

Frameworks (Next.js, FastAPI, Django, Expo, React Native) are anchors. They declare narrow peer-dep / requires-dist ranges that constrain every package in their ecosystem. Pinning satellites before the anchor causes cascade conflicts.

Process:
1. Pick the framework anchor; pin to latest cooldown-safe stable.
2. For each related package, query the anchor's constraint:
   ```sh
   # Python anchor: read requires-dist
   curl -s "https://pypi.org/pypi/<anchor>/<version>/json" | jq -r '.info.requires_dist[]'

   # npm anchor: read peerDependencies + dependencies
   npm view <anchor>@<version> peerDependencies dependencies --json
   ```
3. For each satellite, find the latest cooldown-safe version that satisfies the anchor's constraint.
4. If you can't satisfy both the anchor's constraint AND the security floor for a satellite: bump the anchor to a newer version, then re-pin all satellites.

Common cascade chains (the *pattern*, not specific versions):
- Frontend: `next` -> `react` (matching major) -> `@types/react` -> `@types/node` (matching Node runtime major)
- Frontend tests: `vitest` -> `@vitest/coverage-v8` -> `@stryker-mutator/vitest-runner`
- Storybook: `storybook` -> `@storybook/<framework>` -> `@storybook/<addon-*>` (all same major)
- FastAPI: `fastapi` -> `starlette` -> `pydantic` -> `uvicorn` (anchor changes may require multi-bump)
- ML: `sentence-transformers` -> `transformers` (older `sentence-transformers` pins `transformers<X`; bump together)
- Test tooling: `pytest` -> `pytest-asyncio` / `pytest-anyio` -> plugins (`schemathesis`, `hypothesis`)

For `@types/<pkg>` packages: align `@types/node` major to the Node runtime major. Mismatch typically pulls in a maintenance line of the underlying lib (e.g., `@types/node@22` pulling an older runtime utility) which is more likely to lack provenance.

## Step 3: Pre-emptive security overrides (floors)

Set known security floors upfront. These won't change often and avoid surfacing the same advisories on every fresh install:

```yaml
# pnpm-workspace.yaml: common security floors (verify each upstream is still relevant)
overrides:
  rollup: ">=4.22.4"
  vite: ">=6.2.4"
  esbuild: ">=0.24.0"
  brace-expansion: ">=2.0.1"
  cookie: ">=0.7.0"
  cross-spawn: ">=7.0.5"
```

Don't pre-emptively override packages you haven't surfaced; those create phantom-resolution noise. Add new overrides only as scanners or trust policy raise them.

## Step 4: The first-lock procedure

```sh
just lock         # generate lockfiles
just bootstrap    # install from lockfiles, frozen
just audit        # full security scan chain
```

Expect iteration. Even with prep, novel deps may surface trust downgrades or CVEs that weren't predictable. Use `pre-install-checklist.md` lock-loop table for each failure category.

Goal: converge in 1-2 iterations. Past iteration 3 means a step above was skipped; go back.

## Step 5: Confirm baseline before committing lockfiles

```sh
just audit
# Expect: pip-audit "No known vulnerabilities found"
# Expect: pnpm audit signatures "<N> packages have verified registry signatures"
# Expect: osv-scanner with zero or only-documented-deferred findings
# Document remaining deferred-risk findings inline in the manifests
```

Only then commit `pnpm-lock.yaml`, `uv.lock`, `package.json`, `pyproject.toml`, `pnpm-workspace.yaml` together.

Then close the loop: add/update the repo's `~/eBacon/attacksurface.md` entry (via
`security:attack-surface`), run `security:env-lockdown` REPO mode for the secrets side,
and gate a security-relevant repo with `/security:harden-gate`.

## Verification-failure handling

If a previous pin in the repo cannot be reproduced in the registry now (yanked / typosquat / hallucination), surface as a finding. Do NOT silently overwrite.

Date-stamp pins: comments like `# verified 2026-05-25` next to any unusual pin. Future readers know when last confirmed. Re-verify on lockfile regeneration; pins that worked six months ago may now be too old to satisfy a transitive constraint, or yanked.
