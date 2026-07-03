# Case studies (recent attacks + bootstrap incidents)

Source: playbook §11. Read for trust-downgrade / override decisions and to understand which defense layer (L1-L10) catches what.

## Defense-layer attribution

| Attack | Year | Vector | Lesson / Layer |
|---|---|---|---|
| color.js / chalk (18 packages, 100M+ weekly DLs) | Sept 2024 | Maintainer phishing (T1) | Cooldown (L1) defeats this; malicious versions live for hours |
| ua-parser-js (cryptominer + password stealer) | Oct 2021 | Account takeover (T1) | Lockfile + cooldown; postinstall blocking (L3) stops payload |
| Lottiefiles `lottie-player` (browser-stealer) | Oct 2024 | Credential theft (T1) | Cooldown + behavioral analysis (L4) would catch |
| Ledger `@ledgerhq/connect-kit` (Web3 wallet exfil) | Dec 2023 | NPM_TOKEN compromise (T1) | OIDC Trusted Publishing; provenance (L6) detects publish anomaly |
| Shai-Hulud worm (200+ packages, 700+ accounts) | Sept 2025+ | Self-replicating (T2) | Postinstall blocking (L3); `trustPolicy: no-downgrade` (L6) |
| Mini Shai-Hulud / TanStack (84 versions, 42 packages, 6 minutes) | May 11 2026 | Actions cache poisoning + OIDC (T2/T8) | Cache key scoping (no `restore-keys`); age gate (L1) blocks 6-min window |
| tj-actions/changed-files (23,000+ repos) | March 2025 | Mutable ref hijack (T3) | SHA pinning (L9); Renovate `pinDigests: true` for actions |
| ultralytics PyPI (cryptominer, 60M+ monthly DLs) | Dec 2024 | Workflow compromise -> sdist push (T1) | PyPI Trusted Publishing + PEP 740 attestations |
| xz-utils backdoor (Debian unstable, Fedora rawhide) | March 2024 | Long-game social engineering + build script (T6) | Build script execution (L3, L10); vendoring critical deps |
| TARmageddon (uv CVE-2025-62518) | 2025 | Tool compromise (T8) | Pin toolchain; update via Renovate; verify install attestation |
| Storybook `.env` leak (CVE-2025-68429) | 2025 | Dev tool bundles secrets | `env: () => ({})` in `.storybook/main.ts` |

## Trust-downgrade decision tree

Most npm and PyPI projects added Sigstore / SLSA attestations mid-life. Their older maintenance branches (1.x, 6.x, 2.x) often publish *without* attestations even when actively maintained. `trustPolicy: no-downgrade` will fire on these regularly during a fresh hardened install.

Signal: `npm view <pkg> dist-tags` returns more than just `latest`. Tags like `legacy`, `latest-N` (N < current major), or `next` indicate multi-line maintenance. Non-`latest` lines are usual suspects for trust downgrades.

Diagnose:
```sh
npm view <pkg> dist-tags                    # multi-line scheme detection
for v in <legacy-version> <current-version>; do
  npm view <pkg>@$v dist                    # compare attestations + signatures
done
```

Fix tree:
1. Can the parent dep be bumped to one that uses the trust-attested major? -> **bump the parent** (structural fix; preferred).
2. Is the parent a transitive that can't be bumped (framework wedge)? -> add `pnpm-workspace.yaml#overrides` entry forcing the trust-attested major.
3. Does the trust-attested major break the parent's API expectations? -> read the parent's actual usage; major bumps usually preserve core APIs while removing edge ones. Test before committing.

## Case: undici-types trust downgrade (Tundra bootstrap, May 2026)

What happened: scaffold pinned `@types/node@22.10.5`. `@types/node@22.x` depends on `undici-types@~6.20.0`. pnpm 11's `trustPolicy: no-downgrade` refused:

```
ERR_PNPM_TRUST_DOWNGRADE
High-risk trust downgrade for "undici-types@6.20.0" (possible package takeover)
Earlier versions had provenance attestation, but this version has no trust evidence.
```

Investigation:
- `npm view undici-types@6.20.0 dist` -> has npm PGP signature, NO Sigstore attestations.
- `npm view undici-types@7.1.0 dist` -> HAS Sigstore attestations.

Pattern: undici-types adopted Sigstore at 7.1.0. The 6.x branch is a legitimate maintenance line (still publishing fixes) but never backfilled provenance. pnpm sees "later versions had stronger trust evidence than this one" and flags as possible downgrade attack.

This is a false positive in the attack-detection sense, but doing useful work: surfacing a real provenance gap.

**Wrong fix:** disable `trustPolicy`, use `--ignore-scripts`, downgrade to `trustPolicy: warn`. Removes a major defense to silence one false positive.

**Right fix (structural):** upgrade `@types/node` past the 6.x undici-types dependency:

| @types/node | undici-types range | Has provenance? |
|---|---|---|
| 22.x (Maintenance LTS) | ~6.20.0 | No |
| 24.x (Active LTS) | ~7.16.0 | Yes |
| 25.x (Current) | ~7.8.0+ | Yes |

`@types/node@24.12.4` resolves `undici-types@~7.16.0` (provenance ok). Bonus: `@types/node` now matches the Node runtime major (24.x).

Lessons:
1. Treat trust-policy fires as findings to investigate, not noise to suppress.
2. Cross-reference major-version alignment. If `@types/node` doesn't match Node major, likely on Maintenance LTS branch (may also be on older publishing infra without provenance).
3. Provenance adoption isn't always retroactive.
4. `npm view <pkg>@<ver> dist` is the quickest provenance check per version.

## Case: ua-parser-js trust downgrade (Tundra bootstrap, second-order)

After the @types/node fix, next `pnpm install` failed:

```
ERR_PNPM_TRUST_DOWNGRADE
High-risk trust downgrade for "ua-parser-js@1.0.41" (possible package takeover)
This error happened while installing the dependencies of react-native-web@0.21.2
 at fbjs@3.0.5
```

Chain: `react-native-web -> fbjs@^3.0.4 -> ua-parser-js@^1.0.35`. ua-parser-js famously survived a real account takeover in Oct 2021 (cryptominer), which is presumably why its provenance state is heavily scrutinized.

`npm view ua-parser-js dist-tags`:
```
{ next: '2.0.0', legacy: '1.0.41', latest: '2.0.10' }
```

The `legacy` tag is the tell: 1.x is the deliberately-maintained-stable line; 2.x is the actively-developed-with-Sigstore line.

| Version | Attestations | Signatures |
|---|---|---|
| 1.0.41 | None | Yes (pre-Sigstore PGP) |
| 1.0.42 | None | None |
| 2.0.0 | Yes | Yes |
| 2.0.9 | Yes | Yes |
| 2.0.10 | Yes | Yes |

Why @types/node trick doesn't work here: `react-native-web@0.21.2` declares `fbjs: "^3.0.4"`; `fbjs@3.0.5` declares `ua-parser-js: "^1.0.35"`. No upstream version of fbjs uses ua-parser-js 2.x; Meta hasn't bumped fbjs's parser dep. The structural fix (bump parent) is unavailable.

**Right fix:** pnpm override forcing the trust-attested major.

```yaml
# pnpm-workspace.yaml
overrides:
  ua-parser-js: ">=2.0.9"   # force 2.x line with Sigstore attestations; verified 2026-05-25
```

Safe here because:
- ua-parser-js 2.x preserves `.getResult()` / `.getBrowser()` API used by fbjs.
- 2.x parser data is forward-compatible (newer detection).
- 2.x major bump was primarily ESM packaging, not API surface.

**General override-as-trust-fix pattern:** when trust downgrade fires and parent can't be bumped, override is the legitimate fix IF:
1. Target version has provenance/attestations (verify with `npm view <pkg>@<ver> dist`).
2. Major-version API change won't break the upstream consumer (read changelog).
3. Target version is past the 7-day cooldown.
4. Package is one you'd be comfortable transitively trusting (mature, multi-maintainer, well-adopted).

Documented in override block with reason + case-study cross-reference, so future-you knows why it's there.

Anti-pattern: disabling `trustPolicy` for the install. Removes defense globally to fix one transitive case. Use overrides scoped to the specific package, not global policy weakening.

## Case: esbuild dev-server CORS via drizzle-kit (Kosher audit, 2026-06-25) — deferred-risk by reachability

`pnpm audit` / osv-scanner flagged GHSA-67mh-4wv8-2f99 (esbuild <0.25.0 dev-server CORS, CVSS 5.3 moderate). Chain: `drizzle-kit -> @esbuild-kit/esm-loader -> @esbuild-kit/core-utils -> esbuild@0.18.20` (the deprecated `@esbuild-kit/*` packages, replaced upstream by tsx, pin esbuild ~0.18).

Why neither structural-bump nor override was correct:
- **Structural fix unavailable:** drizzle-kit was already latest and still bundles the deprecated `@esbuild-kit` chain. No parent to bump.
- **Override too brittle:** forcing `esbuild: ">=0.25.0"` spans many esbuild 0.x breaking changes onto a 0.18-era consumer; high risk of breaking drizzle-kit's config bundling (db:generate/migrate/push).
- **Vulnerable path is unreachable:** the advisory triggers only in esbuild `serve` (dev-server) mode. drizzle-kit uses esbuild `transform`/`build` to bundle `drizzle.config.ts` and never starts the dev server, so the CORS code path never executes. Dev-only dep; nothing ships to production.

**Right call:** accept as documented deferred risk (inline in `pnpm-workspace.yaml`), with the durable fix being upstream drizzle-kit migrating off `@esbuild-kit`. Renovate (`vulnerabilityAlerts.minimumReleaseAge: null`) PRs the bump when it lands.

**Reachability is a legitimate fourth option** alongside bump-parent / override / wait-for-upstream: when a fix exists but is unadoptable (brittle) AND the vulnerable code path is provably not invoked by the consumer's usage, document deferred risk rather than forcing a breaking override. Don't swap the whole dependency (e.g. a different ORM) over a dev-only unreachable moderate — alternatives carry their own transitive baggage (Prisma adds a native postinstall query engine; the runtime ORM package was already advisory-free).

## Bootstrap iteration log (Tundra, 2026-05-25): full sweep

Trust downgrades resolved via override (parent-bump unavailable):

| Transitive | Parent chain | Override added | Reason |
|---|---|---|---|
| undici-types@~6.20.0 | `@types/node@22` | bumped parent to `@types/node@24` | 7.x has provenance; major-bump alignment |
| ua-parser-js@^1.0.35 | `react-native-web -> fbjs` | `ua-parser-js: ">=2.0.9"` | 1.x is `legacy` dist-tag; 2.x has attestations |
| semver@^6.3.1 | `@stryker-mutator -> @babel/*` | `semver: ">=7.8.0"` | 6.x is `latest-6` dist-tag; 7.7.0+ has attestations |
| chokidar@^4.0.0 | `@storybook -> fork-ts-checker` | `chokidar: ">=5.0.0"` | 4.0.3-5 dropped provenance mid-line; 5.0.0 restored |

Patchable CVEs (`pnpm audit`):

| Vuln | Package | Override |
|---|---|---|
| GHSA-qx2v-qp2m-jg93 (postcss XSS) | postcss <8.5.10 via next | `postcss: ">=8.5.10"` |
| GHSA-p7fg-763f-g4gf (insecure file perms) | @anthropic-ai/sdk 0.79.0-0.91.1 | `"@anthropic-ai/sdk": ">=0.91.1"` |
| GHSA-q8mj-m7cp-5q26 (qs DoS) | qs 6.11.1-6.15.1 | `qs: ">=6.15.2"` |

Patchable CVEs (`osv-scanner`, caught more than pnpm audit + pip-audit):

| Vuln | Package | Fix |
|---|---|---|
| GHSA-6w46-j5rx-g56g | pytest 8.3.4 | bumped to `pytest==9.0.3` |
| GHSA-2c2j-9gv5-cj73 + GHSA-7f5h-v6xp-fcq8 | starlette 0.41.3 | bumped to `starlette==0.50.0` (within fastapi range) |
| GHSA-69w3-r845-3855 | transformers 4.53.0 | bumped to `transformers==5.8.1` |

Cooldown-driven version selection:
- `@tanstack/react-query@5.100.11`: published 28 minutes inside cutoff. Used 5.100.10 instead.
- `Node 24.16.0`: published 4 days ago, inside cooldown. Used 24.15.0 (40 days old).
- `starlette@1.0.1`: only 3 days old. Used 0.50.0 + accepted PYSEC-2026-161 as deferred.

Final state: 1121 npm packages with verified signatures; 178 Python packages clean per pip-audit; 2 deferred-risk findings (both upstream-bottlenecked, both low real exposure); lockfiles committed and reproducible.

Process lessons:
1. **Run all three scanners.** `pnpm audit`, `pip-audit`, `osv-scanner` each caught CVEs the others missed.
2. **Advisory "patched versions" can be forward-looking.** Cross-check with `npm view <pkg> version` before adding an override.
3. **Renovate's `vulnerabilityAlerts.minimumReleaseAge: null`** is the right escape valve for cooldown-vs-fresh-fix tension.
4. **pip-audit on uv-managed Python needs `--no-deps --disable-pip`.**
5. **Major-version bumps cascade**: ~3-5 deps move when bumping one mid-stack framework.
6. **OSV's `scan source` is the 2.x command** (older `osv-scanner --recursive` doesn't work in 2.2.4+).
