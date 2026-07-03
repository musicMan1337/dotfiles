---
name: dev:viper-dependabot
description: Scan tagemployerservices/Viper for open Dependabot PRs you haven't already commented on, then run a dynamic workflow that audits each PR (supply-chain gate), installs its new lockfile in an isolated worktree, and runs a one-shot frontend build (npm run dev). NO Docker, that's on-demand later via /dev:viper-worktree. Prints a per-PR results table. Triggers on, viper dependabot, scan dependabot prs, check viper dependabot, evaluate viper dep prs, dependabot worktree fanout, viper dep upgrades, /dev:viper-dependabot.
model: opus
---

# /dev:viper-dependabot

Per-PR reviewer for Viper's Dependabot queue. This file is the **scout + reporter**: it discovers PRs, gates on your confirmation, then hands the work set to a **dynamic workflow** (`viper-dependabot.workflow.mjs`) that fans out per-PR agents. The verbose per-PR output lives in the workflow script, not this session, so the orchestrator context stays clean.

The workflow pipelines two stages per PR (no barrier, each PR's build starts the moment its own audit clears):
1. **Audit** (Sonnet, wide fan-out): registry + OSV supply-chain gate, scoped to the changed deps. A RED signal short-circuits to `BLOCKED_AUDIT` with no install and no worktree.
2. **Build** (Opus): create worktree, `npm ci`, one-shot frontend build (`npm run dev`), compatibility analysis, structured verdict. A semaphore caps concurrent builds at `maxBuild` (default 4) without holding back the audits.

## What this does NOT do

- Does not run Docker. The fan-out only installs + frontend-builds (`npm run dev`, a one-shot webpack compile that exits). Docker is built/started **on-demand** later, when you actually pick up a branch via [`/dev:viper-worktree`](./viper-worktree.md). Running 5+ Viper stacks at once would OOM the machine.
- Does not run `viper-new-worktree.sh`. That script symlinks `node_modules` from the main checkout, which defeats testing a new lockfile. The workflow creates worktrees manually with their own `node_modules`.
- Does not comment on, label, approve, or merge any PR. Read-only relative to GitHub.

## Constants

- **Repo:** `tagemployerservices/Viper`
- **Main checkout:** `/Users/derek/eBacon/Viper`
- **Worktree root:** `/Users/derek/eBacon/Viper/.worktrees/`
- **Your GH login:** `musicMan1337`
- **Dependabot author handle in `gh`:** `app/dependabot`
- **Workflow script:** `/Users/derek/dotfiles/claude/commands/dev/viper-dependabot.workflow.mjs`

## Optional args

User may pass PR numbers to scope the run, e.g. `/dev:viper-dependabot 1234 1238`. If provided, skip discovery and use those PR numbers directly (still verify each is a Dependabot PR). User may also pass a concurrency hint like `maxBuild=2` (default 4 concurrent build agents).

## Phase 1: Discover unreviewed Dependabot PRs (inline)

Run from anywhere. All `gh` calls go to `tagemployerservices/Viper`.

1. List open Dependabot PRs with head ref + SHA:
   ```bash
   gh pr list --repo tagemployerservices/Viper \
       --author "app/dependabot" --state open \
       --json number,title,headRefName,headRefOid,url
   ```

2. For each PR, skip if `musicMan1337` already commented OR reviewed (either counts as handled):
   ```bash
   gh pr view <num> --repo tagemployerservices/Viper \
       --json reviews,comments \
       --jq '[.reviews[].author.login, .comments[].author.login] | map(select(. == "musicMan1337")) | length'
   ```
   Non-zero → skip. Zero → include.

3. For each included PR, extract the changed dependency list from the PR body ("Bumps X from A to B") AND the lockfile diff, and **classify ecosystem + directory** (the workflow branches its build logic on these):
   ```bash
   gh pr view <num> --repo tagemployerservices/Viper --json files,headRefName
   ```
   - **ecosystem**: `github-actions` if the head branch starts `dependabot/github_actions/` (or the changed files are all `.github/workflows/*`); else `npm`.
   - **directory**: for npm PRs, the dir the changed `package.json`/`package-lock.json` lives in. `/` = ROOT (in the root workspaces, exercised by `npm run dev`). A sub-path like `/public/application/controllers/api/v1/apiDocs` or `/sandbox` = **SUB-PACKAGE** (NOT in workspaces; root build does not exercise it — the workflow installs/builds scoped to that dir instead). The branch name usually encodes it (`dependabot/npm_and_yarn/<dir>/<pkg>`).
   - Build `{pkg, from, to}` per changed dependency → per-PR `deps`. Pass `ecosystem` and `directory` too (authoritative over the workflow's headRef guess).

4. Print the work set to the user as a numbered list, **annotating non-root PRs** (their build signal differs), e.g.
   ```
   Found 4 unreviewed Dependabot PRs:
   1. #1234  bump axios 1.6.2 → 1.7.4            (root npm)
   2. #1238  bump webpack 5.91.0 → 5.94.0        (root npm)
   3. #1240  bump protobufjs 7.5→7.6 in apiDocs  (sub-package — root build won't exercise it)
   4. #1245  bump actions/checkout 4→6           (github-actions — audit + YAML only, no npm build)

   Run the workflow over these 4 PRs?
   1. Yes
   2. No, let me narrow the list
   ```
   **Wait for confirmation** (this human gate must happen here; the workflow runs autonomously once launched). If the user narrows, re-print and re-ask.

## Phase 2: Launch the dynamic workflow

Once confirmed, call the **Workflow** tool with the saved script and the work set as `args`. Do NOT fan out subagents yourself; the workflow owns the fan-out, throttling, schema validation, and aggregation.

```
Workflow({
  scriptPath: "/Users/derek/dotfiles/claude/commands/dev/viper-dependabot.workflow.mjs",
  args: {
    maxBuild: 4,                       // concurrent build agents (override from user args)
    prs: [
      {
        number: "1234",
        title: "bump axios from 1.6.2 to 1.7.4",
        url: "https://github.com/tagemployerservices/Viper/pull/1234",
        headRef: "dependabot/npm_and_yarn/axios-1.7.4",
        headSha: "<headRefOid from Phase 1>",
        ecosystem: "npm",
        directory: "/",                  // ROOT — root npm ci + npm run dev
        deps: [{ pkg: "axios", from: "1.6.2", to: "1.7.4" }]
      },
      {
        number: "1240",
        title: "bump protobufjs from 7.5.4 to 7.6.1 in /public/application/controllers/api/v1/apiDocs",
        url: "https://github.com/tagemployerservices/Viper/pull/1240",
        headRef: "dependabot/npm_and_yarn/public/application/controllers/api/v1/apiDocs/protobufjs-7.6.0",
        headSha: "<headRefOid>",
        ecosystem: "npm",
        directory: "/public/application/controllers/api/v1/apiDocs",  // SUB-PACKAGE — scoped install, no root build
        deps: [{ pkg: "protobufjs", from: "7.5.4", to: "7.6.1" }]
      },
      {
        number: "1245",
        title: "bump the github-actions group with 2 updates",
        url: "https://github.com/tagemployerservices/Viper/pull/1245",
        headRef: "dependabot/github_actions/github-actions-xxxx",
        headSha: "<headRefOid>",
        ecosystem: "github-actions",     // audit + YAML only; no npm install/build
        deps: [{ pkg: "actions/checkout", from: "4", to: "6" }]
      }
      // ... one entry per confirmed PR
    ]
  }
})
```

The workflow returns `{ verdicts: [...] }`. Each verdict matches the schema in the script: `pr, title, slug, verdict, install_ok, fe_build_ok, deps, usage_files, usage_sample, refactor_required, worktree_path, next_steps` (audit-blocked PRs also carry `audit_findings`). `verdict` ∈ `SAFE | NEEDS_REFACTOR | BLOCKED_INSTALL | BLOCKED_BUILD | SKIPPED_BUILD | BLOCKED_AUDIT` (`SKIPPED_BUILD` = install verified but nothing to frontend-build, e.g. a sub-package with no build script).

**Build behavior by class** (the workflow branches on `ecosystem`/`directory`):
- **root npm** → merge `origin/master` into the worktree (stale-base guard), then root `npm ci --ignore-scripts` + `npm run dev`.
- **sub-package npm** → merge master, then `npm ci` scoped to the sub-dir; runs that package's build script if it has one, else `SKIPPED_BUILD`. Never runs the root `npm run dev` (it wouldn't exercise the change).
- **github-actions** → no npm at all; validates changed workflow YAML + action-input compatibility from the audit/changelog.

The workflow runs in the background; you'll be notified when it completes. Use `/workflows` to watch live progress.

## Phase 3: Report

Parse `verdicts` from the workflow result and print a single terminal table:

```
PR     | Verdict          | Pkg                 | Δ      | Audit | Install | FE build | Usage | Next step
-------|------------------|---------------------|--------|-------|---------|----------|-------|----------
#1234  | SAFE             | axios 1.6.2→1.7.4   | minor  | ok    | ok      | ok       | 12f   | merge
#1238  | NEEDS_REFACTOR   | webpack 5.91→5.94   | minor  | ok    | ok      | ok       | 3f    | update webpack loader rule
#1240  | SAFE             | @types/node 20.10→  | minor  | ok    | ok      | ok       | 0f    | merge
#1245  | BLOCKED_BUILD    | postcss 8.4.31→     | minor  | ok    | ok      | FAIL     | -     | see fe-build.log in <worktree_path>
#1247  | BLOCKED_AUDIT    | left-pad 1.3.0→     | patch  | RED   | -       | -        | -     | new maintainer + 1-day publish; do not install
```

- For `BLOCKED_AUDIT`, fold the RED signal(s) + evidence from `audit_findings` into the Next step column. No worktree exists (audit short-circuited before creation).
- For `BLOCKED_INSTALL` whose `next_steps` cites a master-merge conflict or a stale-base package the PR never touched, report it as "needs Dependabot rebase," not a real dep failure.
- For `SKIPPED_BUILD` (sub-package, no build script), report Install=ok / FE build=n/a and lean on the audit + compat analysis for the verdict.
- For built PRs, include the absolute `worktree_path` so the user can `cd` in. Worktrees are left intact (no auto-cleanup).
- Flag major-version bumps in the table even when `SAFE` (grep can miss dynamic require paths).

End with:
`<n> worktrees ready under /Users/derek/eBacon/Viper/.worktrees/. To actually run one (Docker build + up), use /dev:viper-worktree <slug>. Cleanup with /dev:viper-worktree-cleanup <slug>.`

## Gotchas

- **Discovery + the confirmation gate stay in this skill, never in the workflow.** Workflows run autonomously and can't pause for `AskUserQuestion`. Scout and confirm here, then launch.
- **The verdict schema is enforced by the workflow, not parsed from prose.** The script uses `schema:` on each agent, so structured output is validated at the tool layer (auto-retried on mismatch). No more "re-spawn if the subagent returned prose."
- **Audit only the changed packages, not the whole lockfile.** Scope = packages whose versions changed in THIS PR. Pre-existing CVEs in untouched deps are not this PR's responsibility; flagging them is noise. (Enforced in the audit prompt.)
- **Audit is a gate, before install.** A malicious postinstall runs the moment `npm ci` touches the package; "catch it in review" is too late. RED short-circuits to `BLOCKED_AUDIT` with no worktree. `npm ci --ignore-scripts` is additional defense-in-depth.
- **`npm ci --ignore-scripts` skips the repo's `preinstall` (`npm-force-resolutions`).** Intentional for the safety install. The real build signal is `npm run dev`, whose `predev` runs the lockfile-drift check + webpack compile.
- **`npm run dev` is one-shot.** It's `webpack --progress` (NODE_ENV=development) that compiles and exits, NOT `dev:watch`/`dev:hotreload` (which `--watch` and never return). Never run a watch script in an agent; it hangs the workflow.
- **Stale-base is the #1 false `BLOCKED_INSTALL`.** Dependabot branches are usually cut from an OLD master, so the branch tip can carry stale root-lockfile state that fails `npm ci` for reasons unrelated to the PR (e.g. a `brace-expansion` pin that master has since moved). The workflow now merges `origin/master` into the worktree before installing, so a failure after a clean merge is genuinely the PR's fault; a merge *conflict* → `BLOCKED_INSTALL` with "needs Dependabot rebase." If you see install failures citing a package the PR never touched, suspect stale base, not the bump.
- **Not every Dependabot PR is a root-npm PR.** Sub-package PRs (`apiDocs`, `sandbox`, etc.) live outside the root workspaces, so a root `npm ci`/`npm run dev` "passes" without ever touching the change — non-representative. The workflow installs/builds scoped to the PR's `directory`. github-actions PRs have no npm component at all (audit + YAML only). Always pass `ecosystem`/`directory` from discovery so the build stage branches correctly.
- **Orphaned PRs can't be rebased or recreated.** After a grouped `dependabot.yml` lands, pre-existing individual one-package-per-PR branches reply "the dependabot.yml entry that created this PR has been deleted" to both `@dependabot rebase` and `recreate`. They must be **closed** (Dependabot re-raises grouped/cooled). This skill is read-only and won't do that, but expect it when triaging the queue afterward.
- **No Docker in the fan-out.** Docker build/up is deferred to `/dev:viper-worktree` when the user actually works a branch. This is what keeps concurrency safe; build agents only install + frontend-build.
- **Build concurrency is throttled by a semaphore (`maxBuild`, default 4), not a batch barrier.** Audits all run wide; each PR's build fires as soon as its own audit clears, but waits for a free build slot if `maxBuild` are already in flight. Each worktree is ~1GB of `node_modules`. Raise it on a beefy machine, lower it on a laptop.
- **Symlinking node_modules invalidates the test.** The point is to verify the PR's new lockfile installs cleanly. The workflow creates worktrees with their own `node_modules` and leaves `VIPER_MAIN_NODE_MODULES` unset.
- **Dependabot's GH author is `app/dependabot`, not `dependabot[bot]`.** `--author dependabot[bot]` returns empty.
- **Comment-by-user is a coarse filter.** If you commented on a Dependabot PR for unrelated reasons, this skill skips it. Pass the PR number as an arg to force-include.
- **Resume after a hang.** If one PR's build hangs/fails, relaunch with `Workflow({scriptPath, resumeFromRunId})`; cached PRs return instantly, only the changed one re-runs.
- **Don't delete the worktrees.** User preference is to leave them intact for manual inspection; the report prints absolute paths.
