---
name: setup:package-lockdown
model: opus
description: Harden a repo's third-party package supply chain. Lock down dependencies across Node/pnpm, Python/uv, Rust/Cargo, Go, GitHub Actions, Docker. Generates configs (age gates, hash pinning, postinstall blocking, CVE scanning, provenance, SBOMs, SHA pinning). Works on new and existing repos. Triggers on, lock down packages, harden supply chain, package security, secure install, audit dependencies, package lockdown, new project setup security, supply chain defense, npm pip cargo go security, postinstall blocking, age gate, cooldown deps, sigstore provenance.
allowed-tools: Agent, Bash, Read, Write, Edit, Glob, Grep, Skill
---

Goal: harden this repo's third-party package supply chain against the 8 attack vectors (T1 maintainer takeover; T2 self-replicating worm; T3 mutable ref hijack; T4 typosquat; T5 postinstall abuse; T6 build-time exec; T7 lockfile drift; T8 compiler compromise).

## Source of truth

Authoritative playbook: `/Users/derek/eBacon/obsidian/eBacon/security/package-lockdown.md`. This skill packages that doc as `_refs/`. When the playbook updates materially, re-extract the changed sections.

## Skill invariants (non-negotiable)

Four rules that separate a hardening skill from a new attack surface. Violate any one and the skill is worse than doing nothing:

1. **Verify before writing.** No version pin enters a manifest without same-invocation registry verification. LLM-suggested versions (yours included) hallucinate plausible-looking values, especially when cooldown windows are involved. §6 Step 0 of the playbook documents real incidents where AI output gave `pnpm 11.3.0` (real but 1 day old, inside cooldown), `Node 22.11.0` (Maintenance LTS, not Active), `uv 0.5.13` (months stale). Treat your prior as a hint; the registry is truth.

2. **Date-stamp every pin.** Append `# verified YYYY-MM-DD` (today's date from harness context, not memory) to every version line written. Lets the next run judge staleness without re-verifying everything.

3. **No auto-install.** This skill writes configs and reports. The user runs `lock` + `bootstrap` + `audit`. Skill itself never becomes an install vector. If a step seems to need `pnpm install` / `uv sync` / `cargo build` to validate, stop and print the command for the user.

4. **Refuse on uncertainty.** If a registry is unreachable (offline, rate-limited, malformed reply), REFUSE to write that pin. Surface as a finding. Never guess from training data, ever.

## Alignment with the security:* family

- **Execution policy (spine).** Mechanical scopes (NEW BOOTSTRAP, EXISTING AUDIT config-writing, registry lookups) run inline. A REAL security VERDICT (the ADD-ONE-PACKAGE "is X safe" call on a package actually about to be installed, or any INCIDENT-scope compromise walk) follows the spine's execution policy (`/Users/derek/dotfiles/claude/commands/security/harden/references/spine.md`): when the main session model is not Fable, route it through `fable:hunt` (`assess <package or incident + your structured observations>`) and relay the verdict; when the session is Fable, render inline unless it self-stops.
- **Grading bridge (for security:harden / harden-gate).** The L-layers are not one kind of control. L2 hash pinning, L3 postinstall blocking, and L9 SHA pinning are structural BOUNDARIES (do not degrade against a smarter attacker); L1 age gate and L5 CVE scanning are RACES (they bet the ecosystem flags malware inside the window); L6 provenance / `trustPolicy` moves the root of trust outside the registry account (Tier 2). A lockdown'd repo is boundaries plus races, layered; never report it as "supply chain solved."
- **Close the loop.** After a bootstrap or a material audit: update the repo's entry in `~/eBacon/attacksurface.md` (via `security:attack-surface`) so the inventory's Defenses line matches reality; for a security-relevant repo, finish with `/security:harden-gate` on the shipped config. The full new-repo ritual is three skills: this one (deps), `security:env-lockdown` REPO mode (secrets/CC config), `security:attack-surface` (inventory entry).

## Operational constraints

- **Delegate ALL registry lookups, repo scans, and CVE queries to Haiku subagents.** Do not run npm/curl/jq directly to gather many versions; spawn a Haiku subagent with the package list and have it return a verified map. Registry verification is mechanical lookup work; running Opus on it is waste, and per-package outputs poison main context.
- **Run subagents in parallel** for multi-ecosystem repos. Sequential lookups multiply latency.
- **Load only relevant ecosystem references.** Read `_refs/ecosystem-<X>.md` only for ecosystems detected in Phase 1. Do NOT read all of them up front.

## Phase 1: Detect

Spawn one Haiku subagent to walk the repo and report:

- Ecosystems present (`package.json`, `pyproject.toml`/`uv.lock`, `Cargo.toml`, `go.mod`, `Dockerfile*`, `.github/workflows/`)
- Existing hardening signals: `pnpm-workspace.yaml` (allowBuilds, minimumReleaseAge, trustPolicy, blockExoticSubdeps), `uv.toml` (exclude-newer, require-hashes), `.npmrc` (save-exact, strict-peer-dependencies, engine-strict), `renovate.json` (cooldown rules), `.github/dependabot.yml`, `.github/workflows/security.yml`, `deny.toml`, lockfile presence + commit status
- Package manager (`pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` / `bun.lockb`)
- Pinning style sample: 5 random deps' version strings (exact `1.2.3` vs `^1.2.3` vs `~1.2.3` vs range)
- Workspace/monorepo structure

Report under 300 words.

## Phase 2: Classify scope

Pick one path based on detection:

| Signal | Scope | Path |
|---|---|---|
| No lockfile, empty/scant manifest, or user said "new project / init / scaffold" | **NEW BOOTSTRAP** | Full §3.5 day-zero. Load `_refs/bootstrap-day-zero.md`. |
| Lockfile + deps exist, hardening config missing or weak (`^` ranges everywhere, no allowBuilds, no update-bot cooldown, Dependabot or Renovate) | **EXISTING AUDIT** | Gap audit. Load relevant `_refs/ecosystem-<X>.md` + `_refs/anti-patterns.md`. |
| User asked "add package X" / "is X safe to install" / "should I use Y" | **ADD-ONE-PACKAGE** | Load only `_refs/pre-install-checklist.md`. Skip ecosystem configs. |
| User mentioned a CVE drop, suspected compromise, hijacked Action | **INCIDENT** | Load `_refs/incident-response.md`. Walk the scenario; do not write configs. |

Announce the classification in one sentence. If ambiguous, present numbered options.

## Phase 3: Verify versions (parallel Haiku)

For every meta-tool version (Node LTS, pnpm, uv, Python minor, cargo, go toolchain) and every package pin you intend to write, spawn one Haiku subagent per ecosystem (parallel) with this brief:

> Query the canonical registry for these packages: [list]. For each, report (a) current latest stable version, (b) latest version published more than 7 days ago, (c) iso publish timestamp of latest. Commands by ecosystem: npm/pnpm uses `npm view <pkg> version` and `npm view <pkg> time --json`; PyPI uses `curl -s https://pypi.org/pypi/<pkg>/json`; crates.io uses `curl -s https://crates.io/api/v1/crates/<pkg>`; Go uses `go list -m -versions <module>`; GitHub releases use `gh release list --repo <o>/<r> --limit 10`; Homebrew uses `brew info --json=v2 <formula>`; Node LTS uses `curl -s https://nodejs.org/dist/index.json`. Apply 7-day cooldown filter. Return one line per package: `<pkg> latest=<v> cooldown-safe=<v> latest-published=<iso>`. If unreachable: `<pkg> UNREACHABLE`. If not found: `<pkg> NOT FOUND`. Do not guess. Under 50 words per package.

Use returned values, not prior knowledge, when writing pins.

## Phase 4: Write configs

Load only the references you need for detected ecosystems. Each `_refs/ecosystem-<X>.md` contains: install command, hardened config(s), pinning rule, critical commands, ecosystem-specific pitfalls.

Pinning rule (per playbook §4.1, §4.2):
- App `dependencies` / `devDependencies` / `[project].dependencies`: exact (no `^`, no `~`).
- Pnpm `overrides` / uv `[tool.uv.constraints]`: floor (`>=fixed-version`). Floors force all transitive copies to satisfy the constraint without downgrading sub-deps that need newer.
- Engines / `requires-python`: exact patch or exact minor (`==3.12.*`).
- Lockfile: auto, exact + integrity hashes, committed, never hand-edited.

Date-stamp every pin written with today's date from the harness context (e.g., `react = "19.2.0"  # verified 2026-05-25`). For EXISTING AUDIT, add the comment when adjusting a pin; flag pre-existing undated pins in the report.

For pnpm `allowBuilds`, pre-populate the native-binary baseline from `_refs/bootstrap-day-zero.md` Step 1, with a justification comment per entry. For the update bot, pull the **Dependabot template (estate default)** or the Renovate alternative from `_refs/ci-stack.md`. For GitHub Actions, every action gets its 40-char SHA verified by the same Haiku loop (one subagent call per action, returns SHA + tag-it-matched + commit-date).

## Phase 5: Report + next commands

Print:

1. **Scope and scale.** NEW BOOTSTRAP / EXISTING AUDIT / ADD-ONE-PACKAGE / INCIDENT; ecosystems touched; count of pins written; count of pre-existing pins flagged for staleness; count of pre-existing pins that failed registry verification (yanked / typo / hallucination upstream).
2. **What was already hardened.** EXISTING AUDIT only.
3. **What changed.** Files touched, with a bullet per file naming the defense layer added (L1 age gate, L2 hash pinning, L3 postinstall blocking, L4 behavioral analysis, L5 CVE scanning, L6 provenance, L7 dep review, L8 SBOM, L9 SHA pinning, L10 egress restriction).
4. **Deferred risks.** Any CVE whose patched version doesn't exist yet upstream, or trust downgrades you couldn't fix structurally. Cite the §6.5 / §11 pattern that applies.
5. **Commands for the user to run, in order.** Numbered. Typical: `pnpm install --frozen-lockfile` or `uv lock && uv sync --frozen`, then `pnpm audit --audit-level=high && pnpm dlx npm@latest audit signatures`, then `osv-scanner scan source --recursive .`, then ecosystem-specific (`uvx pip-audit --requirement <(uv export --format requirements-txt --frozen) --no-deps --disable-pip --strict` for Python). NEVER run them yourself.
6. **Next-step prompt.** Tell the user: "If any of those error out, paste the error message back to me and I'll match it to the lock-loop playbook (`_refs/pre-install-checklist.md` lock-loop errors table)."
7. **Close the loop.** Update the repo's `~/eBacon/attacksurface.md` entry (via `security:attack-surface`) with the new Defenses posture; for a security-relevant repo, finish with `/security:harden-gate`. New repos: also run `security:env-lockdown` REPO mode.

## Phase 6: Lock-loop iteration

When the user pastes an error from one of the install/audit commands:

Read `_refs/pre-install-checklist.md` (it includes the §6.5 lock-loop error table). Match the error to a row. Apply the documented fix pattern. Do not invent novel responses; the table grows from real incidents.

For `ERR_PNPM_TRUST_DOWNGRADE` specifically, read `_refs/case-studies.md` (undici-types, ua-parser-js) first. The structural fix (bump parent past unsigned maintenance branch) is preferred over the override escape valve. Fall back to override only after confirming the parent can't be bumped.

If the error doesn't match any row, surface it as a gap and propose adding a row to the playbook + this skill.

## Gotchas

- **AI-generated version numbers are hallucination-prone.** Top-1 failure mode. Examples from the playbook's Tundra case study: `pnpm 11.3.0` (real but inside cooldown), `Node 22.11.0` (Maintenance LTS, not Active), `uv 0.5.13` (months stale). Three of five tool pins from research output were wrong. Always verify against the registry in the same invocation, regardless of how confident the prior feels.
- **Brew `installed` field can lag the upstream registry by ~24 hours.** Use `npm view` / PyPI JSON / `gh release list` as authority, not brew.
- **Homebrew binaries built from source (`cargo install`, `go build`, `pip install`, `npm install`, `make`) won't match upstream SLSA attestations.** `gh attestation verify $(brew --prefix uv)/bin/uv` returning 404 is by design (different SHA-256), not a missing attestation. Trust brew's audit chain locally; verify the *official downloaded release artifact* (or Astral-signed container image) when CI/Docker matters. Check with `brew cat <formula> | head -30`.
- **Same-day vulnerability fix vs the 7-day cooldown.** Tension. Resolve via Renovate's `vulnerabilityAlerts.minimumReleaseAge: null` to bypass cooldown only for security-flagged bumps. Never disable cooldown globally to fix one finding.
- **Trust-policy fires are findings to investigate, not noise to suppress.** When `trustPolicy: no-downgrade` fires, structural fix (bump parent past unsigned maintenance branch) is usually available and better than the override escape valve. See `_refs/case-studies.md`.
- **Don't auto-follow package-manager self-update prompts.** `pnpm self-update`, `npm install -g pnpm@latest` bypass cooldown. Let Renovate gate manager updates.
- **uv-managed Python lacks `ensurepip`; pip-audit's default mode SIGABRTs.** Use `uvx pip-audit --requirement <file> --no-deps --disable-pip --strict`.
- **OSV-Scanner 2.x reorganized commands.** `osv-scanner --recursive` is gone in 2.2.4+; use `osv-scanner scan source --recursive <dir>`.
- **`engineStrict: true` + cooldown-locked Node = chicken-and-egg.** If you pin `engines.node` to a version inside cooldown, `pnpm install` will refuse. Step back to previous LTS patch before locking.
- **Storybook leaks `.env` into static builds** (CVE-2025-68429, Storybook 7.0-10.1.9). When auditing a repo with Storybook, check for `env: () => ({})` in `.storybook/main.ts`.
- **`pull_request_target` + checkout of PR HEAD = secrets exfil vector.** Flag any `pull_request_target` workflow during EXISTING AUDIT.
- **`actions/cache` with broad `restore-keys` on sensitive workflows = poisoning vector.** The Mini Shai-Hulud TanStack attack (May 2026) rode this. Flag during EXISTING AUDIT.
- **Don't trust `Today's date is...` in agent context to imply future registry contents.** Registry holds what was published; dates don't unlock future versions. Always cross-check with the registry's own timestamp (`npm view <pkg> time`, PyPI `releases` keys).
- **Cooldown for the package manager itself is a tradeoff, not a rule.** Pinning pnpm/uv to a version inside cooldown is defensible for product engineering (managers are well-audited, Renovate-managed; cooldown does its real work on the *transitive* dep graph flowing through them). For high-stakes / regulated environments, stay strict. Document the choice inline.
- **Major-version cascades.** Bumping one framework anchor (Next.js, FastAPI, React Native) cascades to 3-8 satellites. Bump in dependency order: anchor, then typed bindings (`@types/<lib>`), then test framework, then testing addons. Re-lock between layers to catch conflicts early.
- **`osv-scanner.toml`: one unknown key voids the whole file.** The expiry field is `ignoreUntil` (`validUntil` is rejected), and rejection is per-FILE ("Ignored invalid config file"), so every ignore silently stops applying. After any toml edit, re-run the scanner and confirm exit code plus the per-ID filter messages. (Snout, 2026-08-14.)
- **Advisory-ID ignores are unconditional and outlive fixes silently.** A no-fix ignore stays green after upstream publishes a fix. Pair every ignore with `ignoreUntil` (hard backstop) AND a CI fix-watch job that queries `api.osv.dev/v1/vulns/<id>` and fails on a `fixed` event or `withdrawn`. Reference implementation: Snout `.github/workflows/security.yml` `ignored-advisory-fix-watch`.
- **Red-green any fix-watch/detector script against a known-fixed advisory before trusting it.** First Snout attempt failed open: `echo "$body"` expanded escape sequences in the OSV JSON into control chars, jq errored, and the known-fixed test case read "no fix". Use `printf '%s'`, and route unparseable replies to a warning, never to the no-fix branch.
- **osv-scanner "unused ignores" can be a false warning** (2.2.4 alias-counting quirk: it lists IDs as unused in the same run whose filter messages show them working). Trust the filter messages and exit code.
- **pnpm's "Packages: +N -M" counts node_modules mutations, not lockfile entries.** To verify a manifest change did what you predicted, diff the lockfile's `packages:` key set against HEAD. Exact-pinning also re-resolves override floors, so expect small cooldown-safe transitive refreshes (e.g. a `>=7.8.0` floor stepping 7.8.1 -> 7.8.5), not a byte-identical lockfile.
- **Dependabot is three separate switches.** `dependabot.yml` (version updates), vulnerability alerts, and automated security fixes are independent; a repo with a perfect dependabot.yml can still have security updates OFF. Verify/enable: `gh api [-X PUT] repos/<o>/<r>/vulnerability-alerts` and `.../automated-security-fixes`.

## Growing this skill

Each time the user reports an error or surprise this skill missed, add a row to `_refs/pre-install-checklist.md` (lock-loop table) or to Gotchas above. §11 case studies grow too. Treat the source playbook and this skill as one document spread across files; keep them in sync.

## References

| File | Use when |
|---|---|
| `_refs/bootstrap-day-zero.md` | NEW BOOTSTRAP scope. §3.5 day-zero + §6 Step 0 registry-verification commands. |
| `_refs/pre-install-checklist.md` | ADD-ONE-PACKAGE scope or lock-loop error matching. §6 9-step + §6.5 error table. |
| `_refs/ecosystem-node-pnpm.md` | `package.json` detected. §4.1 pnpm config + pinning. |
| `_refs/ecosystem-python-uv.md` | `pyproject.toml` / `uv.lock` detected. §4.2 uv config. |
| `_refs/ecosystem-rust-cargo.md` | `Cargo.toml` detected. §4.3 cargo + `deny.toml`. |
| `_refs/ecosystem-go.md` | `go.mod` detected. §4.4. |
| `_refs/ecosystem-actions.md` | `.github/workflows/` detected. §4.5 SHA pinning + least-priv. |
| `_refs/ecosystem-docker.md` | `Dockerfile*` detected. §4.6 digest pinning + cosign. |
| `_refs/ecosystem-cli-binaries.md` | Installing a CLI tool. §4.7 preference order. |
| `_refs/ci-stack.md` | §5 layered tooling + Renovate template + branch protection. |
| `_refs/incident-response.md` | INCIDENT scope. §7 scenarios A/B/C. |
| `_refs/anti-patterns.md` | EXISTING AUDIT scope. §8 anti-pattern table for gap detection. |
| `_refs/case-studies.md` | Trust-downgrade / override decisions. §11 worked examples. |
