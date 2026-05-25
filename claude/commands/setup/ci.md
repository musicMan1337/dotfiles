---
name: setup:ci
model: opus
description: Enhance an existing project's CI by hardening and extending what's there, not replacing it. Discovers current CI infrastructure (GitHub Actions, GitLab CI, CircleCI, Azure Pipelines, Jenkins, etc.), researches modern best practices for the detected platform via Haiku subagents, identifies gaps, and proposes additive changes that align with existing conventions. Triggers on, setup ci, enhance ci, harden ci, ci pipeline, github actions, workflow setup, add ci checks, ci coverage, ci performance, ci caching, pipeline review, workflow audit, optimize workflow, faster ci, ci flake, ci concurrency, branch protection.
allowed-tools: Agent, Bash, Read, Write, Edit, Glob, Grep, Skill
---

Goal: harden and enhance THIS repo's existing CI. Orientation is additive, not replacement. Respect existing conventions, tooling choices, and pipeline structure. Propose changes that fit alongside what's already there; do not rebuild from scratch unless the user explicitly asks for it.

## Scope (read this first)

This skill owns CI architecture: workflow structure, caching, concurrency, matrix builds, observability (status summaries, annotations, SARIF), PR automation, branch protection mechanics, runner choice, secrets surface, performance.

It does NOT own:

- **Supply-chain security CI** (OSV-Scanner, pip-audit, pnpm audit, Trivy, dependency-review, Renovate, SBOM, SHA pinning, branch-protection security contexts, cosign image signing). That belongs to `setup:package-lockdown` (which has the full §5 CI stack playbook). If those are missing, mention them and tell the user to run `/setup:package-lockdown`. Stay in lane.
- **Language linting / formatting / typecheck** config (eslint, biome, ruff, mypy, clippy, golangci-lint, husky, lint-staged). That belongs to `setup:linting`. CI invocation of those tools is fine here; their config is not.

Overlap between the three is intentional but bounded: `setup:linting` writes the config, `setup:ci` wires the gate, `setup:package-lockdown` wires the supply-chain scanners.

## Operational constraints

- **Delegate ALL discovery and online research to Haiku subagents.** Walking workflow files and looking up platform best-practices are mechanical lookup tasks. Running Opus on them wastes tokens and poisons main context.
- **Discovery + research run in parallel.** No reason to sequence "what does this repo have" and "what's modern for this platform."
- **Online research tool choice.** Best-practices research is targeted (specific platform's docs), so use Exa MCP (`mcp__exa__*`) if total queries are <=2; otherwise Firecrawl for broader sweeps. Pull from official docs (docs.github.com/actions, docs.gitlab.com/ee/ci, circleci.com/docs, etc.) before blog posts.

## Phase 1: Discover (parallel Haiku subagents)

Spawn two subagents in parallel.

### Subagent A: existing CI infrastructure

Walk the repo and report what's already there. Brief:

> Inventory this repo's CI setup. Cover:
> - **Platform**: `.github/workflows/`, `.gitlab-ci.yml`, `.circleci/config.yml`, `azure-pipelines.yml`, `Jenkinsfile`, `.drone.yml`, `bitbucket-pipelines.yml`, `buildkite/`, `.cirrus.yml`, `wrangler.toml` triggers. List every CI config file found.
> - **Workflow inventory**: one line per workflow with file name + `on:` triggers + job names. Do not paste full bodies.
> - **Existing gates**: what runs on PR vs push to main vs release/tag? What's listed as required in branch protection (run `gh api repos/<owner>/<repo>/branches/<default>/protection 2>/dev/null` if available; report 404 / 403 if not)?
> - **Test runner**: detect from `package.json` scripts, `pyproject.toml`, `Cargo.toml`, `go.mod` test conventions. Note coverage tooling (vitest --coverage, pytest-cov, c8, nyc, etc.).
> - **Build / deploy targets**: container registry pushes (ECR, GHCR, Docker Hub, GCR), npm/PyPI publish, GitHub Pages, Vercel/Netlify, AWS/GCP/Azure deploys, Fly.io, Cloudflare Workers.
> - **Notifications**: Slack webhooks, email, GitHub Discussions, Datadog/Sentry/PagerDuty hooks.
> - **Caching**: `actions/cache` usage (paths + key strategy), GitLab cache keys, CircleCI restore_cache, Docker layer caching, Turbo remote cache, Nx remote cache.
> - **Matrix / parallelism**: which jobs fan out, on what dimensions (os, node-version, python-version, shard).
> - **Runners**: GitHub-hosted vs self-hosted; OS/arch list; ARC (Actions Runner Controller) signals.
> - **Secrets surface**: env vars referenced (do NOT read values); OIDC vs long-lived tokens (look for `permissions: id-token: write` and `aws-actions/configure-aws-credentials@*` with `role-to-assume`).
> - **Concurrency blocks**: any `concurrency:` keys; `cancel-in-progress` settings.
> - **Versions in use**: Node/Python/Go/Rust/Ruby major-minor declared in workflows.
>
> Report under 500 words.

### Subagent B: modern best practices for the detected platform

After Subagent A surfaces the platform (default to GitHub Actions if unclear), research current best practices. Brief:

> Platform: <X>. Research current state-of-the-art for CI hardening and performance on this platform via Exa MCP (targeted lookup of official docs). Focus on:
> - Performance: cache strategies, matrix optimization patterns, conditional-skip / paths-filter / change-detection (dorny/paths-filter, nx affected, turbo affected), partial test execution.
> - Reliability: retry-on-failure, flake quarantine, `timeout-minutes`, fail-fast tradeoffs, required vs advisory checks.
> - Observability: status badges, GitHub Step Summary, annotations, SARIF upload, JUnit test result publishing (dorny/test-reporter), coverage upload (Codecov / Coveralls).
> - Concurrency: cancel-in-progress for PRs, queue for main/deploys, deploy serialization, environment-scoped concurrency.
> - PR automation: required-checks, auto-merge (github-actions auto-merge bot, kodiak, mergify), label-based triggers, draft-PR handling.
> - Workflow security mechanics (not supply-chain scanners): least-privilege `permissions:` blocks, `persist-credentials: false`, `pull_request_target` pitfalls, env-isolation of user-controlled inputs.
>
> Do NOT recommend specific version pins; version-verification lives in `/setup:package-lockdown`. Just name actions/orbs/tools and what they solve.
>
> Report under 500 words. Cite source URLs.

## Phase 2: Classify maturity

Cross-reference the two reports:

| Signal | Maturity | Approach |
|---|---|---|
| No CI files at all | **None** | Confirm scope with the user; most "enhance CI" intents assume existing CI. Numbered options: bootstrap minimal CI here, or move to `/setup:package-lockdown` first, or abort. |
| Single workflow, runs tests only | **Minimal** | Highest-value additions only: lint gate, typecheck, build gate, concurrency block. 2-3 proposals max; not a full overhaul. |
| Multiple workflows with lint+test+build, no advanced features | **Standard** | Look for gaps in caching, concurrency, matrix, PR automation, status reporting. Targeted additions. |
| Mature CI with caching, matrix, custom actions, deploy pipelines | **Advanced** | Audit for outdated patterns (un-pinned actions flagged for `/setup:package-lockdown`, missing concurrency groups, broad cache `restore-keys`, missing `timeout-minutes`, missing `permissions: {}`). Propose hardening fixes, not new infrastructure. |

Announce classification in one sentence. If ambiguous, present numbered options.

## Phase 3: Identify gaps + propose additions

For each gap, decide: additive (fits alongside existing) or replacement (would conflict)?

- **Additive examples**: typecheck job parallel to existing test job; `concurrency:` block to cancel stale PR runs; `timeout-minutes:` on jobs that lack it; coverage reporting from existing test runner output; status check for required PR labels; cache step for an uncached dep-install; Step Summary publishing.
- **Replacement examples (avoid unless the user asks)**: swapping the test runner; moving from one CI platform to another; consolidating multiple workflows into a reusable workflow when the user organized them deliberately; rewriting bash scripts into JS actions.

For each proposed addition, prepare:
1. **What** it does, one sentence.
2. **Why** it matters here, tied to a specific signal in Subagent A's report (never generic "it's a best practice").
3. **Where** it lives, file + job + step.
4. **The diff**, as a draft. Do not write to disk yet.

## Phase 4: Present + ask before writing

Print a numbered list of proposals, each with what/why/where. Ask which to apply (numbered options if more than 3; otherwise list with letter selectors).

After user confirms, write the changes with Edit (not Write) to preserve existing structure and comments. Date-stamp any pinning-adjacent additions (`# verified YYYY-MM-DD`); for action SHA pins specifically, defer to `/setup:package-lockdown` rather than inventing pins here.

## Phase 5: Local validation before reporting done

Cheap, safe checks only. Do not push, do not trigger runs.

```sh
# yaml parses
for f in .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null; do
  [ -f "$f" ] && yq -e . "$f" >/dev/null && echo "OK $f" || echo "FAIL $f"
done

# actionlint (if available)
command -v actionlint >/dev/null && actionlint .github/workflows/*.yml

# zizmor for workflow security misconfigs (uv-installed, lives in setup:package-lockdown's world but useful here too)
command -v uvx >/dev/null && uvx zizmor .github/workflows/ 2>/dev/null || true
```

Report results + a `git diff --stat` summary. The user runs CI to verify end-to-end.

## Gotchas

- **The user has organized their CI deliberately.** When you see "weird" structure (single huge workflow, no caching, deliberately serial jobs, hand-rolled shell scripts where an action exists), assume there's a reason before "fixing" it. Ask if the structure is intentional before refactoring. This is the central distribution shift for this skill: defaults will pull you toward replacement; resist.
- **Don't replicate `setup:package-lockdown`.** OSV-Scanner, pip-audit, Trivy, Renovate, dependency-review, SHA pinning for actions, SBOM generation, branch-protection security contexts all live there. If you're tempted to add them here, redirect the user instead.
- **Required checks have inertia.** Adding a new required status check to branch protection means every open PR fails until they pass it. Default: propose new checks as advisory first, then required after they stabilize on main for a week. Tell the user this tradeoff explicitly when proposing required-check changes.
- **Matrix builds multiply runner minutes.** Adding `os: [ubuntu, macos, windows]` triples cost; adding `node-version: [18, 20, 22]` triples again. Confirm cost tolerance before adding a matrix dimension. If the project doesn't actually need cross-platform/cross-version coverage, don't add it.
- **GitHub Actions cache has a 10GB org-wide limit + 7-day eviction.** Aggressive caching strategies hit the limit and silently regress (older caches evict, new jobs lose hits). Don't add cache to every job; profile first. For monorepos, scope cache keys to specific lockfile hashes, not broad globs.
- **`concurrency.cancel-in-progress: true` cancels mid-run deploys.** Apply to PR runs, not to main / production deploys. Use different concurrency groups per context: `${{ github.workflow }}-${{ github.ref }}` for PRs, `${{ github.workflow }}-deploy` (no cancel) for releases.
- **Self-hosted runners persist state across jobs.** Anti-pattern for trust: one malicious PR poisons subsequent runs. If the repo uses self-hosted runners on a public repo, flag during EXISTING AUDIT regardless of what else changes.
- **OIDC vs long-lived tokens.** If discovery finds long-lived `NPM_TOKEN`, `AWS_ACCESS_KEY_ID`, `GCP_SA_KEY`, `DOCKERHUB_TOKEN` in repo/org secrets, raise as a finding even though this skill doesn't fix it directly. OIDC is the structural fix (PyPI Trusted Publishing, AWS `configure-aws-credentials` with `role-to-assume`, etc.).
- **`actions/checkout` with `persist-credentials: true` (default) leaves the GITHUB_TOKEN in `.git/config`.** Subsequent steps can read it. Add `persist-credentials: false` unless a later step needs to push.
- **`workflow_dispatch` inputs are user-controlled.** If interpolated into `run:` blocks unquoted, script injection vector. Same rules as PR titles: pass through `env:` then quote `"$VAR"`.
- **Test parallelization differs by runner.** Jest's `--maxWorkers`, pytest-xdist's `-n`, Go's `-parallel`, vitest's `--threads` each have platform-specific tuning. Don't blindly maximize; ask about runner capacity first. On standard 2-vCPU GitHub-hosted runners, `--maxWorkers=2` is usually optimal; auto often picks 4 and thrashes.
- **`needs:` chains create false serializations.** A job declaring `needs: [build]` waits for `build` even if it doesn't read its artifacts. Audit the `needs:` graph during discovery; surface unnecessary dependencies as proposals to remove (cuts wall-time).
- **Status badges show `latest run`, not `latest run on default branch`.** Default badges can show red when only a feature-branch run failed. Use `?branch=main` (or your default branch name) in the badge URL.
- **Reusable workflows vs composite actions confused.** Reusable workflow (`uses: org/repo/.github/workflows/x.yml@ref`) runs as a separate job; composite action (`uses: org/repo/path@ref`) runs as steps in the calling job. Picking wrong affects logs, runner choice, and what `secrets:` you can pass.
- **`if: always()` vs `if: success() || failure()`.** `always()` runs even on cancellation; `success() || failure()` doesn't. Use the latter for cleanup steps that shouldn't run on cancel; use `always()` only for telemetry steps that must always emit.
- **PR runs from forks don't get secrets** (and shouldn't). Workflows that require secrets to function will silently no-op for fork PRs. Detect this gap and propose a labeled-run pattern if integration tests need secrets, or accept that fork PRs are spec-only.

## What this skill does NOT do

- Generate vulnerability scanners, dep auditors, Renovate config, SBOM steps, branch-protection security contexts -> `/setup:package-lockdown`.
- Set up linting / formatting / typecheck tools (the language-level config) -> `/setup:linting`. CI invocation of those tools is fair game; their config is not.
- Run installs or deploys.
- Modify branch protection rules without explicit user confirmation. Even with confirmation, propose required-check additions as advisory first.
- Invent version pins for actions. SHA pinning lives in `/setup:package-lockdown`.
