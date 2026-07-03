export const meta = {
  name: 'viper-dependabot',
  description: 'Audit + install + frontend-build each Viper Dependabot PR in its own worktree, return per-PR verdicts. No Docker (on-demand later).',
  phases: [
    { title: 'Audit', detail: 'registry + OSV gate per PR, scoped to changed deps (Sonnet)' },
    { title: 'Build', detail: 'worktree + npm ci + npm run dev + compat analysis (Opus, throttled)' },
  ],
}

// ---------------------------------------------------------------------------
// args: { prs: [{number,title,url,headRef,headSha,deps:[{pkg,from,to}],
//                ecosystem?,directory?}],
//         maxBuild?: number }   // maxBuild = concurrent heavy build agents
//   ecosystem: 'npm' | 'github-actions' (discovery should pass it; derived if absent)
//   directory: target dir for npm PRs, e.g. '/' or
//              '/public/application/controllers/api/v1/apiDocs'. Authoritative
//              over the headRef-derived guess. Root = in workspaces; sub-package = not.
// returns: { verdicts: [VERDICT...] }
// ---------------------------------------------------------------------------

const REPO = 'tagemployerservices/Viper'
const MAIN = '/Users/derek/eBacon/Viper'
const WORKTREES = '/Users/derek/eBacon/Viper/.worktrees'

const _args = typeof args === 'string' ? JSON.parse(args) : (args || {})
const { prs = [], maxBuild = 4 } = _args

// Classify a PR's ecosystem + target directory. Drives build-stage behavior:
// github-actions = no npm; root npm = root install + webpack; sub-package npm =
// install/build scoped to the sub-dir (root npm ci/run dev would not exercise it).
function classify(pr) {
  const ref = pr.headRef || ''
  if (pr.ecosystem === 'github-actions' || /\/github_actions\//.test(ref)) {
    return { eco: 'github-actions', dir: null, root: false }
  }
  let dir = pr.directory || '/'
  if (!pr.directory) {
    // weak fallback; discovery passing `directory` is authoritative
    const m = ref.match(/^dependabot\/npm_and_yarn\/(.+)\/[^/]+$/)
    if (m && m[1] && !m[1].startsWith('multi')) dir = '/' + m[1]
  }
  const root = dir === '/' || dir === ''
  return { eco: 'npm', dir: root ? '/' : dir, root }
}

const SLUG_RULE =
  'lowercase the head branch, replace every non-alphanumeric run with a single "-", collapse repeats, trim leading/trailing "-", cut to 40 chars'

// ---- schemas ---------------------------------------------------------------

const AUDIT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['pr', 'blocked', 'findings', 'warnings', 'deps'],
  properties: {
    pr: { type: 'string' },
    blocked: { type: 'boolean', description: 'true if ANY signal was RED' },
    findings: {
      type: 'array',
      description: 'RED signals only',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['pkg', 'signal', 'value', 'evidence'],
        properties: {
          pkg: { type: 'string' },
          signal: { type: 'string', description: 'age|provenance|maintainer|deprecation|lifecycle|size|cve' },
          value: { type: 'string' },
          evidence: { type: 'string' },
        },
      },
    },
    warnings: {
      type: 'array',
      description: 'YELLOW signals (do not block)',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['pkg', 'signal', 'value'],
        properties: {
          pkg: { type: 'string' },
          signal: { type: 'string' },
          value: { type: 'string' },
        },
      },
    },
    deps: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['pkg', 'from', 'to', 'delta'],
        properties: {
          pkg: { type: 'string' },
          from: { type: 'string' },
          to: { type: 'string' },
          delta: { type: 'string', description: 'patch|minor|major' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: [
    'pr', 'title', 'slug', 'verdict', 'install_ok', 'fe_build_ok',
    'deps', 'usage_files', 'usage_sample', 'refactor_required',
    'worktree_path', 'next_steps',
  ],
  properties: {
    pr: { type: 'string' },
    title: { type: 'string' },
    slug: { type: 'string' },
    verdict: {
      type: 'string',
      enum: ['SAFE', 'NEEDS_REFACTOR', 'BLOCKED_INSTALL', 'BLOCKED_BUILD', 'SKIPPED_BUILD'],
    },
    install_ok: { type: 'boolean' },
    fe_build_ok: { type: 'boolean', description: 'npm run dev (one-shot webpack compile) succeeded' },
    audit_warnings: {
      type: 'array',
      items: { type: 'object', additionalProperties: true },
    },
    deps: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['pkg', 'from', 'to', 'delta', 'breaking_notes'],
        properties: {
          pkg: { type: 'string' },
          from: { type: 'string' },
          to: { type: 'string' },
          delta: { type: 'string' },
          breaking_notes: { type: 'string' },
        },
      },
    },
    usage_files: { type: 'integer' },
    usage_sample: { type: 'array', items: { type: 'string' } },
    refactor_required: { type: 'array', items: { type: 'string' } },
    worktree_path: { type: 'string' },
    next_steps: { type: 'string' },
  },
}

// ---- prompt builders -------------------------------------------------------

function depsList(pr) {
  return (pr.deps || [])
    .map((d) => `${d.pkg} ${d.from} -> ${d.to}`)
    .join(', ') || '(extract from the PR lockfile diff)'
}

function auditPrompt(pr) {
  return `You are the SUPPLY-CHAIN AUDIT gate for ONE Dependabot PR against \`${REPO}\`. Do NOT install, do NOT create a worktree, do NOT build. Registry + OSV inspection only, then return the structured verdict.

PR #${pr.number}: ${pr.title}
Head SHA: ${pr.headSha}
Changed deps (scope is STRICT, audit ONLY these): ${depsList(pr)}

Borrowing /setup:package-lockdown's gate philosophy: the new lockfile is untrusted until this passes. Audit ONLY the changed packages above, never pre-existing CVEs in untouched deps.

For each changed package, query the registry directly (no install):
\`\`\`bash
npm view <pkg>@<to> --json time dist.attestations maintainers deprecated scripts dist.unpackedSize
npm view <pkg>@<from> --json maintainers
\`\`\`
Signals:
- Age (cooldown): time.<to> vs now. RED if < 3 days, YELLOW if < 14 days.
- Provenance: dist.attestations present+valid. RED if prior version HAD provenance and new one dropped it; YELLOW if missing on a popular package.
- Maintainer drift: new maintainer in <to> not in <from> + recent publish = RED.
- Deprecation: deprecated field non-empty on target = RED.
- Lifecycle scripts: NEW preinstall/install/postinstall not in <from> = RED; unchanged existing = YELLOW.
- Tarball size: dist.unpackedSize > 3x previous = YELLOW.

Then OSV-scan the PR's proposed lockfile WITHOUT installing:
\`\`\`bash
tmp=$(mktemp -d)
gh api repos/${REPO}/contents/package-lock.json?ref=${pr.headSha} --jq '.content' | base64 -d > "$tmp/package-lock.json"
cp ${MAIN}/package.json "$tmp/package.json"
osv-scanner --lockfile="$tmp/package-lock.json" --format=json > "$tmp/osv.json"
\`\`\`
Filter OSV findings to ONLY the changed packages. HIGH/CRITICAL the bump does NOT fix = RED; MEDIUM = YELLOW; CVEs the bump fixes = ignore.

Age thresholds are heuristics: a 2-day @types/* or major-OSS bump with active maintainers is fine; a 2-day single-maintainer bump after an ownership transfer is not. Use judgment.

Set blocked=true if ANY signal is RED (put it in findings with evidence). YELLOWs go to warnings, do not block. Always populate deps with semver delta per package. pr must equal "${pr.number}".`
}

function buildPrompt(pr, audit, kind) {
  const warns = JSON.stringify(audit.warnings || [])

  const setup = `You are evaluating ONE Dependabot PR against \`${REPO}\` that has ALREADY PASSED the supply-chain audit. Do NOT re-audit. Create its worktree, verify it, analyze compatibility, return the structured verdict. Use absolute paths.

PR #${pr.number}: ${pr.title}
URL: ${pr.url}
Head branch: ${pr.headRef}
Head SHA: ${pr.headSha}
Ecosystem: ${kind.eco}${kind.eco === 'npm' ? `   Target directory: ${kind.dir}${kind.root ? ' (ROOT, in workspaces)' : ' (SUB-PACKAGE, NOT in root workspaces)'}` : ''}
Changed deps: ${depsList(pr)}
Audit warnings to carry into audit_warnings: ${warns}

WORKTREE SETUP (in order):
1. Slug from the head branch: ${SLUG_RULE}. Path = ${WORKTREES}/<slug>. If that path already exists (slug collision with another PR), append a short disambiguator from the changed dep, e.g. -<pkg>-<to>.
2. cd ${MAIN}
3. git fetch origin ${pr.headRef} && git update-ref refs/heads/${pr.headRef} origin/${pr.headRef}
4. git worktree add ${WORKTREES}/<slug> ${pr.headRef}
5. Copy ${MAIN}/.env to the worktree .env (npm run dev's predev/devSetup reads it), override COMPOSE_PROJECT_NAME=viper-worktree-<slug>, leave VIPER_MAIN_NODE_MODULES UNSET (use the worktree's own node_modules).
6. cd ${WORKTREES}/<slug>
7. STALE-BASE GUARD (critical): Dependabot branches are often based on an OLD master, so the branch tip can carry stale root-lockfile state that fails \`npm ci\` for reasons unrelated to this PR. Merge current master in so you test the PR as it WOULD merge:
   git merge --no-edit --no-ff origin/master
   - If the merge CONFLICTS: \`git merge --abort\`, set verdict=BLOCKED_INSTALL, install_ok=false, fe_build_ok=false; next_steps must say the branch needs a Dependabot rebase (conflicts with master); skip install/build but STILL do the compatibility analysis below.
   - A CLEAN merge means any npm ci failure below is attributable to THIS PR's deps, not pre-existing base drift. (This is the #1 cause of false BLOCKED_INSTALLs — do not skip it.)
`

  let verify
  if (kind.eco === 'github-actions') {
    verify = `VERIFY (github-actions PR — NO npm component; do NOT run npm ci or npm run dev):
8. The diff is GitHub Actions workflow YAML only. Validate each changed \`.github/workflows/*.yml\`: run \`actionlint\` if installed, else parse each changed YAML for validity.
9. Set install_ok=true and fe_build_ok=true (no npm install/build applies here). verdict=SAFE unless a changed action input/usage at a call site collides with a documented breaking change in the action bump — then NEEDS_REFACTOR with each collision in refactor_required. next_steps: note it's CI-only and to merge after the Actions checks pass on the branch.
`
  } else if (kind.root) {
    verify = `INSTALL + FRONTEND BUILD (ROOT npm PR; NO Docker, Docker is on-demand later):
8. npm ci --ignore-scripts 2>&1 | tee npm-ci.log
   - lifecycle scripts blocked (defense-in-depth; audit already cleared the changed pkgs). Skips the repo preinstall npm-force-resolutions intentionally.
   - If npm ci FAILS after a CLEAN master merge: the failure is REAL (this PR's deps). Set verdict=BLOCKED_INSTALL, install_ok=false, fe_build_ok=false, skip step 9.
9. npm run dev 2>&1 | tee fe-build.log
   - ONE-SHOT webpack compile (NODE_ENV=development) that exits; predev runs a lockfile-drift check + webpack build. NOT a watch server (never run dev:watch/dev:hotreload).
   - If it FAILS: set verdict=BLOCKED_BUILD, fe_build_ok=false.
`
  } else {
    verify = `INSTALL (SUB-PACKAGE npm PR; the changed lockfile lives in ${kind.dir}, which is NOT part of the root workspaces — a ROOT \`npm ci\`/\`npm run dev\` would NOT install or exercise this change and is NOT a valid test):
8. Install IN THE SUB-PACKAGE dir: cd ${WORKTREES}/<slug>${kind.dir} && npm ci --ignore-scripts 2>&1 | tee npm-ci.log
   - If npm ci FAILS after a CLEAN master merge: REAL failure for this PR. Set verdict=BLOCKED_INSTALL, install_ok=false.
9. Inspect that sub-package's package.json scripts. If it has a build/compile/bundle script, run it ONE-SHOT (never a watch) and tee to fe-build.log; set fe_build_ok by its exit. If there is NO build script, set fe_build_ok=true and verdict=SKIPPED_BUILD (install verified; nothing to frontend-build), and say so in next_steps. Do NOT run the ROOT \`npm run dev\` for a sub-package PR (non-representative).
`
  }

  const tail = `COMPATIBILITY ANALYSIS (always, regardless of install/build outcome):
Per changed dep: determine semver delta (majors get the most scrutiny). For minors/majors, check the CHANGELOG between from and to (Firecrawl for broad lookup, Exa for known canonical sources like axios GH releases). Flag breaking API changes, removed exports, runtime-behavior changes, peer-dep bumps, Node floor bumps. Grep the worktree (ripgrep, exclude node_modules and .worktrees) for real usage sites; report usage_files count + up to 5 representative paths in usage_sample. Cross-reference affected usage against the breaking changes.

VERDICT:
- BLOCKED_INSTALL: npm ci failed after a clean merge, OR the master merge conflicted (needs rebase).
- BLOCKED_BUILD: the build/frontend compile failed.
- SKIPPED_BUILD: install verified but there was no applicable build (sub-package with no build script).
- NEEDS_REFACTOR: a real usage site collides with a documented breaking change (list each in refactor_required).
- SAFE: verified AND no refactor needed (carry YELLOW warnings into audit_warnings).
- Always set worktree_path to the absolute ${WORKTREES}/<slug> and write a one-sentence next_steps.
- Major-version bumps: flag in next_steps even when SAFE (grep can miss dynamic require paths).
- pr must equal "${pr.number}". Do NOT start containers, push, delete the worktree, or comment on the PR.`

  return setup + '\n' + verify + '\n' + tail
}

// Caps concurrent heavy build agents without a phase barrier: each PR's build
// starts as soon as its own audit clears, but waits here if maxBuild are in flight.
function makeSemaphore(max) {
  let active = 0
  const waiters = []
  return {
    async acquire() {
      while (active >= max) await new Promise((r) => waiters.push(r))
      active++
    },
    release() {
      active--
      const w = waiters.shift()
      if (w) w()
    },
  }
}

function blockedAuditVerdict(pr, audit, errMsg) {
  return {
    pr: String(pr.number),
    title: pr.title,
    slug: '',
    verdict: 'BLOCKED_AUDIT',
    install_ok: false,
    fe_build_ok: false,
    audit_findings: audit ? audit.findings : [{ signal: 'audit_error', evidence: errMsg || 'audit agent failed' }],
    audit_warnings: audit ? audit.warnings : [],
    deps: audit ? audit.deps : pr.deps || [],
    usage_files: 0,
    usage_sample: [],
    refactor_required: [],
    worktree_path: '(none, audit short-circuited before worktree creation)',
    next_steps: audit
      ? 'RED audit signal, do not install. See audit_findings; file with security if maintainer/lifecycle related.'
      : 'Audit agent failed, re-run this PR individually.',
  }
}

// ---- run -------------------------------------------------------------------

if (!prs.length) {
  log('No PRs in work set; nothing to do.')
  return { verdicts: [] }
}

log(`Pipelining ${prs.length} PRs: each builds as soon as its audit clears (max ${maxBuild} concurrent builds).`)

const buildSlots = makeSemaphore(maxBuild)

// No barrier: every PR runs audit -> build independently. A passing audit hands
// straight to its build (gated by buildSlots); a RED/failed audit short-circuits.
const verdicts = await pipeline(
  prs,
  // Stage 1: supply-chain audit gate (cheap, wide). Returns the audit object or null.
  (pr) =>
    agent(auditPrompt(pr), {
      label: `audit:#${pr.number}`,
      phase: 'Audit',
      schema: AUDIT_SCHEMA,
      model: 'sonnet',
      agentType: 'claude',
    }).catch(() => null),

  // Stage 2: build + frontend-build + analyze, throttled by the semaphore.
  async (audit, pr) => {
    if (!audit || audit.blocked) return blockedAuditVerdict(pr, audit)

    await buildSlots.acquire()
    try {
      const v = await agent(buildPrompt(pr, audit, classify(pr)), {
        label: `build:#${pr.number}`,
        phase: 'Build',
        schema: VERDICT_SCHEMA,
        model: 'opus',
        agentType: 'claude',
      })
      return { ...v, audit_warnings: v.audit_warnings || audit.warnings || [] }
    } catch (e) {
      return {
        pr: String(pr.number),
        title: pr.title,
        slug: '',
        verdict: 'BLOCKED_BUILD',
        install_ok: false,
        fe_build_ok: false,
        audit_warnings: audit.warnings || [],
        deps: audit.deps || pr.deps || [],
        usage_files: 0,
        usage_sample: [],
        refactor_required: [],
        worktree_path: '(build agent errored)',
        next_steps: `Build agent errored: ${e.message}. Re-run this PR individually.`,
      }
    } finally {
      buildSlots.release()
    }
  }
)

return { verdicts: verdicts.filter(Boolean) }
