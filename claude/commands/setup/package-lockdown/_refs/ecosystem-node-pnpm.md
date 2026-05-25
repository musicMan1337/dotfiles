# Ecosystem: Node.js (pnpm)

Use when `package.json` detected. Source: playbook §4.1.

Why pnpm vs npm/Yarn/Bun: pnpm v11+ has `minimumReleaseAge`, `strictDepBuilds`, `blockExoticSubdeps`, `trustPolicy: no-downgrade`, content-addressable store, no phantom deps, built-in. Other managers require external tooling for the same defenses; Bun has no postinstall blocking.

## Install

Node 25+ drops bundled Corepack. Install pnpm directly via Homebrew (preferred) or `npm install -g pnpm@<exact-version>` pinned in `package.json#packageManager`.

```sh
# macOS, preferred
brew install pnpm

# CI alternative (uses npm's sha512 integrity chain)
npm install -g pnpm@<verified-version>
```

## `pnpm-workspace.yaml` (single source of truth for supply-chain settings)

```yaml
packages:
  - "apps/*"
  - "packages/*"

# === Supply-chain hardening ===

# (L3 Postinstall blocking) Block postinstall/preinstall scripts in ALL deps
# unless explicitly allowed.
dangerouslyAllowAllBuilds: false
strictDepBuilds: true

# Whitelist packages that legitimately need build scripts. Audit every entry:
# `pnpm why <pkg>` to understand why a transitive needs it. See
# bootstrap-day-zero.md Step 1 for the native-binary baseline.
allowBuilds:
  "@biomejs/biome": true     # downloads native Rust binary
  esbuild: true              # native binary
  "@next/swc-darwin-arm64": true
  "@next/swc-darwin-x64": true
  "@next/swc-linux-x64-gnu": true
  "@next/swc-linux-x64-musl": true
  sharp: true                # libvips bindings
  lightningcss: true         # native CSS parser
  # NEVER add: husky, semantic-release, analytics packages, ad SDKs

# Reject transitive deps sourced from git:// or raw tarball URLs.
# (Direct deps you trust may still use them.)
blockExoticSubdeps: true

# (L1 Age gate) Refuse versions published less than 7 days ago.
# Default in pnpm 11 is 24h; bump to 7 days for higher trust.
minimumReleaseAge: 10080  # minutes (= 7 days)

# Per-package exclusions for the age gate (well-vetted critical packages).
minimumReleaseAgeExclude: []

# (L6 Provenance) If a previously-signed package downgrades its provenance,
# fail the install. Catches account takeover replacing signed publish workflow.
# IMPORTANT: also fires on legitimate maintenance branches that predate
# the project's adoption of Sigstore (e.g., undici-types 6.x has no
# attestations; 7.1.0+ does). When this hits, investigate first; do NOT
# relax the policy. Structural fix is usually to upgrade past the
# unsigned maintenance branch. See case-studies.md.
trustPolicy: no-downgrade

# Verify content-addressable store integrity before linking.
verifyStoreIntegrity: true

# Enforce engines field declared by packages.
engineStrict: true

# Internal workspaces resolve via workspace: protocol, not the registry.
linkWorkspacePackages: true
```

## `.npmrc` at repo root

```ini
engine-strict=true
strict-peer-dependencies=true
auto-install-peers=false
lockfile=true
verify-store-integrity=true
link-workspace-packages=true
prefer-workspace-packages=true

# CRITICAL: `pnpm add <pkg>` writes the exact version, not a caret range.
save-exact=true
save-prefix=
```

## Root `package.json` (engines + overrides)

```json
{
  "name": "my-app",
  "private": true,
  "engines": {
    "node": "<verified-Node-LTS-patch>",
    "pnpm": "<verified-pnpm-version>"
  },
  "packageManager": "pnpm@<verified-pnpm-version>",
  "pnpm": {
    "overrides": {
      "rollup": ">=4.22.4",
      "vite": ">=6.2.4",
      "esbuild": ">=0.24.0",
      "brace-expansion": ">=2.0.1",
      "cookie": ">=0.7.0",
      "cross-spawn": ">=7.0.5"
    }
  }
}
```

## Pinning rule

| Location | Pin style | Example |
|---|---|---|
| `dependencies` / `devDependencies` | **Exact** (no `^`, no `~`) | `"react": "19.2.0"  # verified 2026-05-25` |
| `pnpm.overrides` | **Floor** (`>=fixed-version`) | `"rollup": ">=4.22.4"` |
| `pnpm-lock.yaml` | Exact + integrity hashes (committed, never hand-edited) | auto |
| `engines.node` | Exact patch | `"22.11.0"` |

Floor for overrides forces *all* transitive copies to satisfy the constraint without downgrading sub-deps that need newer (`"rollup": "4.22.4"` exactly would downgrade a sub-dep needing `^4.25`).

Override as trust-policy escape valve: when `trustPolicy: no-downgrade` fires on a transitive and the parent can't be bumped, an override forcing the trust-attested major version is the right fix. Each must (a) target a version with provenance, (b) be API-compatible with the consumer, (c) be past 7-day cooldown, (d) be documented inline. See `case-studies.md`.

## Install commands

```sh
# Local first-time install
pnpm install

# CI / production
pnpm install --frozen-lockfile --prefer-offline

# Add a new package (writes exact version)
pnpm add <pkg>

# Check provenance attestations
pnpm dlx npm@latest audit signatures

# Audit known CVEs
pnpm audit --audit-level=high
```

## What pnpm avoids by default vs npm

| Risky behavior | npm | pnpm 11+ |
|---|---|---|
| Auto-runs postinstall | Yes | **No** (blocked unless in allowBuilds) |
| Resolves `*` to latest at install time | Yes | Yes, but mitigated by age gate |
| Allows phantom dep imports | Yes | **No** (symlinked) |
| Default `^` on `npm add` | Yes | **No** (with `save-exact=true`) |
