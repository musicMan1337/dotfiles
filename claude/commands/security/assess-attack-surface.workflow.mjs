export const meta = {
  name: 'assess-attack-surface',
  description: 'Deep, adversarially-verified security assessment of one or more eBacon attack surfaces; scales depth to criticality, recommends a testing cadence from criticality + exposure + findings + cost.',
  phases: [
    { title: 'Recon', detail: 'confirm surface + drift per system (Sonnet)' },
    { title: 'Assess', detail: 'multi-dimension security review, depth by criticality (Sonnet/Opus)' },
    { title: 'Verify', detail: 'adversarial skeptic pass per finding, kills false positives (Sonnet/Opus)' },
    { title: 'Score', detail: 'risk score + cadence recommendation + log row (Opus)' },
  ],
}

// ---------------------------------------------------------------------------
// args: {
//   today: "YYYY-MM-DD",                    // stamped by the launcher (no Date in workflows)
//   filePath: "/Users/derek/eBacon/attacksurface.md",
//   targets: [{ name, repo, path, type, criticality, exposure:[tags], entry? }]
// }
// returns: { assessments: [ASSESSMENT...] }
//
// Efficiency levers (spend tracks risk, per the user's cost ask):
//  - assessment DEPTH (dimension count) scales with criticality
//  - verification VOTES scale with criticality + finding severity
//  - model tier scales with criticality (Sonnet for routine, Opus for Critical + all scoring)
//  - global concurrency capped at 4 (workflows bypass the subagent-gate hook)
// SECURITY-REVIEW AGENTS ARE PINNED TO SONNET/OPUS, NEVER the session model:
// the session model (Fable) false-refuses cyber review; Sonnet/Opus do not.
// ---------------------------------------------------------------------------

const _args = typeof args === 'string' ? JSON.parse(args) : (args || {})
const { today = 'unknown-date', filePath = '/Users/derek/eBacon/attacksurface.md', targets = [] } = _args

const MAX_CONC = 4 // self-limit: workflow agent() bypasses the CryptoGuard hook

// ---- concurrency guard -----------------------------------------------------
function makeSemaphore(max) {
  let active = 0
  const waiters = []
  return {
    async acquire() { while (active >= max) await new Promise((r) => waiters.push(r)); active++ },
    release() { active--; const w = waiters.shift(); if (w) w() },
  }
}
const slot = makeSemaphore(MAX_CONC)
// Every security agent goes through here. No A() call awaits another A() while
// holding a slot, so the semaphore only ever queues, never deadlocks.
async function A(prompt, opts) {
  await slot.acquire()
  try { return await agent(prompt, opts) }
  finally { slot.release() }
}

// ---- depth policy (the efficiency lever) -----------------------------------
const DIMENSIONS = {
  'authn-authz': 'Authentication & authorization: missing/broken authN, shared or weak secrets, non-constant-time secret compares, IDOR / missing authz checks, trusted-header or session spoofing, token/scope over-grant.',
  'exposure-network': 'Network exposure: reachable beyond its intended audience? cloud public-by-default (e.g. Cloud Run --allow-unauthenticated), gateway bypass via a direct backend/run.app URL, missing VPN/firewall gating, permissive CORS, open ports, unauthenticated metrics/health endpoints leaking internals.',
  'injection-input': 'Input handling: SQL injection (including dynamic-SQL string concat), command/template injection, SSRF (URL/HTML fetchers, PDF renderers reading file:// or remote url()), path traversal, unsafe deserialization, stored/reflected XSS on web properties.',
  'secrets-config': 'Secrets & config: secrets/salts/password-hashes committed to git history, plaintext credentials on disk with no secrets-manager indirection, TLS validation disabled (e.g. TrustServerCertificate=True), DEBUG logging of assertions/tokens, secrets in workflow logs.',
  'supply-chain': 'Supply chain: unpinned/mutable GitHub Action tags, EOL language/runtime still serving traffic, missing dependency vuln scanning in CI, dependency-confusion on internal package scopes, postinstall-script risk, over-broad registry/PAT token scope.',
  'platform-misconfig': 'Platform-specific misconfiguration for THIS stack plus missing hardening: absent security headers/CSP, no WAF, no rate limiting, unverified inbound webhook signatures, verbose error disclosure, framework security filters disabled.',
}
const ALL_DIMS = Object.keys(DIMENSIONS)
const MED_DIMS = ['authn-authz', 'exposure-network', 'secrets-config', 'supply-chain']
const LOW_DIMS = ['exposure-network', 'secrets-config', 'supply-chain']

function normCrit(c) {
  const s = String(c || '').toLowerCase()
  if (s.includes('crit') || s.includes('🔴')) return 'Critical'
  if (s.includes('high') || s.includes('🟠')) return 'High'
  if (s.includes('med') || s.includes('🟡')) return 'Medium'
  if (s.includes('low') || s.includes('🟢')) return 'Low'
  return 'High' // unknown -> assess conservatively
}
function dimsFor(crit) {
  if (crit === 'Critical' || crit === 'High') return ALL_DIMS
  if (crit === 'Medium') return MED_DIMS
  return LOW_DIMS
}
function heavyModel(crit) { return crit === 'Critical' ? 'opus' : 'sonnet' }
function votesFor(crit, sev) {
  const hot = (crit === 'Critical' || crit === 'High') && (sev === 'C' || sev === 'H')
  return hot ? 2 : 1
}

// ---- deterministic cadence prior (consistency; the Opus scorer may refine) --
// Criticality sets a FLOOR (the most-frequent cadence habit alone justifies).
// A confirmed C/H finding tightens one step. Cost-awareness loosens ONE step,
// but only for cheap, low-criticality, non-public, clean systems, so spend
// tracks risk without ever leaving a Critical/High system under-tested.
const CADENCE_ORDER = ['Monthly', 'Quarterly', 'Semi-annual', 'Annual', 'Biennial / on-change']
const CADENCE_FLOOR = { Critical: 'Quarterly', High: 'Semi-annual', Medium: 'Annual', Low: 'Annual' }
function cadencePrior(crit, exposure, worstSev, agentCount) {
  const exp = Array.isArray(exposure) ? exposure : []
  const cw = { Critical: 4, High: 3, Medium: 2, Low: 1 }[crit] ?? 3
  const ew = Math.max(1, ...exp.map((t) => {
    const u = String(t).toUpperCase()
    if (u.includes('PUBLIC')) return 3
    if (u.includes('TOKEN') || u.includes('OAUTH') || u.includes('VPN')) return 2
    return 1
  }))
  const fw = { C: 3, H: 2, M: 1 }[worstSev] ?? 0
  const risk = cw * 2 + ew + fw // 3..17, a summary number for the report

  const base = CADENCE_FLOOR[crit] || 'Annual'
  let idx = CADENCE_ORDER.indexOf(base)
  if (worstSev === 'C' || worstSev === 'H') idx = Math.max(0, idx - 1) // tighten
  const isPublic = exp.some((t) => String(t).toUpperCase().includes('PUBLIC'))
  const clean = !worstSev || worstSev === 'L'
  const expensive = agentCount >= 8
  if (crit === 'Low' && clean && !isPublic) idx = Math.min(CADENCE_ORDER.length - 1, idx + 1) // cost-aware loosen
  const costAdjusted = CADENCE_ORDER[idx]
  return { risk, base, costAdjusted, expensive, agentCount }
}

// ---- schemas ---------------------------------------------------------------
const SURFACE_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['system', 'confirmed_exposure', 'endpoints', 'authn', 'secrets_locations', 'drift'],
  properties: {
    system: { type: 'string' },
    confirmed_exposure: { type: 'array', items: { type: 'string' }, description: 'exposure tags actually evidenced in-repo' },
    endpoints: { type: 'array', items: { type: 'string' }, description: 'concrete routes/ports/hosts reachable' },
    authn: { type: 'string', description: 'how a client authenticates, cite the file' },
    secrets_locations: { type: 'array', items: { type: 'string' }, description: 'NAMES/PATHS only, never values' },
    dependencies: { type: 'string', description: 'runtime + notable deps + EOL/version concerns' },
    drift: { type: 'string', description: 'what changed vs the inventory entry, or "none observed"' },
  },
}
const FINDINGS_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['dimension', 'findings'],
  properties: {
    dimension: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['title', 'severity', 'where', 'exploit', 'confidence'],
        properties: {
          title: { type: 'string' },
          severity: { type: 'string', enum: ['C', 'H', 'M', 'L'] },
          where: { type: 'string', description: 'file:line / endpoint / config key' },
          exploit: { type: 'string', description: 'concrete attacker path: inputs/state -> impact' },
          confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
        },
      },
    },
  },
}
const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['real', 'adjusted_severity', 'reason'],
  properties: {
    real: { type: 'boolean', description: 'true only if genuinely exploitable AND in scope for this system' },
    adjusted_severity: { type: 'string', enum: ['C', 'H', 'M', 'L'] },
    reason: { type: 'string' },
  },
}
const ASSESSMENT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['system', 'recommended_criticality', 'recommended_cadence', 'cadence_rationale', 'cost_note', 'next_due', 'log_row', 'summary', 'confirmed'],
  properties: {
    system: { type: 'string' },
    recommended_criticality: { type: 'string', enum: ['Critical', 'High', 'Medium', 'Low'] },
    recommended_cadence: { type: 'string' },
    cadence_rationale: { type: 'string' },
    cost_note: { type: 'string', description: 'what this assessment cost (agent count / tier) and whether that argues for a longer cadence' },
    next_due: { type: 'string', description: 'human phrase, e.g. "2026-10 (quarterly)"' },
    log_row: { type: 'string', description: 'one markdown table row: | date | system | scope | C/H/M/L counts | drift | next_due |' },
    summary: { type: 'string', description: 'two-sentence verdict for the report' },
    confirmed: {
      type: 'array',
      items: {
        type: 'object', additionalProperties: false,
        required: ['title', 'severity', 'where', 'exploit'],
        properties: {
          title: { type: 'string' },
          severity: { type: 'string', enum: ['C', 'H', 'M', 'L'] },
          where: { type: 'string' },
          exploit: { type: 'string' },
        },
      },
    },
  },
}

// ---- prompt builders -------------------------------------------------------
const AUTHZ_FRAME = 'This is an AUTHORIZED defensive security assessment of the operator\'s OWN eBacon (TAGEmployerServices) infrastructure, for hardening. Read-only: inspect repo metadata/config/source; do NOT deploy, restart, scan live hosts, or hit live endpoints. Never copy secret VALUES into your output; cite names/paths only.'

function reconPrompt(t) {
  return `${AUTHZ_FRAME}

RECON for ONE system: ${t.name} (repo ${t.repo}, path ${t.path}, type ${t.type}).
Its current inventory entry (may be stale):
"""
${t.entry || '(no entry provided; discover from scratch)'}
"""

Confirm the CONCRETE attack surface from the repo (README, Dockerfile, docker-compose, .env.example, appsettings, web.config, *.ini, .github/workflows, cloudbuild/gateway specs, routes/controllers, policies). Enumerate real endpoints/ports/hosts, how a client authenticates (cite files), the exposure tags actually evidenced, where secrets live (NAMES/PATHS only), and dependency/EOL concerns. Report DRIFT vs the entry above (new endpoint, changed auth, new dep, new host) or "none observed". Targeted reads, not a full-tree dump. Return the structured surface.`
}

function assessPrompt(t, surface, dimKey) {
  return `${AUTHZ_FRAME}

SECURITY ASSESSMENT of ${t.name} (${t.repo}, ${t.path}), dimension: ${dimKey}.
Focus ONLY this dimension: ${DIMENSIONS[dimKey]}

Confirmed surface from recon:
- exposure: ${JSON.stringify(surface.confirmed_exposure)}
- endpoints: ${JSON.stringify(surface.endpoints)}
- authn: ${surface.authn}
- secrets: ${JSON.stringify(surface.secrets_locations)}
- deps: ${surface.dependencies || 'n/a'}

Find REAL, exploitable issues in this dimension, grounded in files you actually read. For each: a concrete exploit path (attacker inputs/state -> impact), the file:line/endpoint/config-key, a severity (C/H/M/L), and your confidence. Prefer a few high-confidence findings over a long speculative list. If the dimension is clean, return an empty findings array. Do NOT report pre-existing CVEs in untouched third-party deps as if they were this system's design flaw (note them only if the system's config actually exposes them).`
}

function verifyPrompt(t, f) {
  return `${AUTHZ_FRAME}

ADVERSARIAL VERIFICATION of ONE candidate finding on ${t.name} (${t.repo}, ${t.path}). Your job is to REFUTE it. Default to real=false unless you can trace a concrete, in-scope, exploitable path in the actual code/config.

Finding: "${f.title}" [claimed ${f.severity}]
Where: ${f.where}
Claimed exploit: ${f.exploit}

Open the cited files. Is it genuinely reachable and exploitable given this system's real exposure and auth, or is it mitigated/theoretical/out-of-scope (e.g. dev-only, gated by a control the finder missed, or a false pattern-match)? Set real=true ONLY if you confirmed the path. Give an adjusted severity and a one-line reason.`
}

function scorePrompt(t, confirmed, prior, agentCount) {
  const counts = confirmed.reduce((a, f) => (a[f.severity] = (a[f.severity] || 0) + 1, a), {})
  return `${AUTHZ_FRAME}

SCORE + CADENCE for ${t.name} (type ${t.type}, current inventory criticality ${t.criticality}, exposure ${JSON.stringify(t.exposure)}).

Confirmed findings (survived adversarial verification): ${JSON.stringify(confirmed)}
Severity counts: ${JSON.stringify(counts)}

Deterministic cadence prior (already accounts for criticality, exposure, worst finding, and assessment cost):
- risk score ${prior.risk}/17
- base cadence "${prior.base}"
- cost-adjusted cadence "${prior.costAdjusted}" (this run used ~${agentCount} agents; expensive=${prior.expensive})

Produce the final assessment. Recommend a criticality (confirm or change the inventory's, with reason if changed) and a testing cadence. Start from the cost-adjusted prior; only deviate if the confirmed findings justify it, and say why in the rationale. The cadence must balance risk against assessment cost: do not recommend Monthly/Quarterly for a low-risk, cheap-to-break-nothing system just because it is public. Write a two-sentence verdict, a cost_note, a human next_due phrase relative to ${today}, and a single markdown log row:
| ${today} | ${t.name} | <dims assessed> | ${(counts.C||0)}C/${(counts.H||0)}H/${(counts.M||0)}M/${(counts.L||0)}L | <drift or "baseline"> | <next_due> |`
}

// ---- per-system assessment -------------------------------------------------
async function assessSystem(t) {
  const crit = normCrit(t.criticality)
  const dims = dimsFor(crit)
  const model = heavyModel(crit)
  let agentCount = 0

  // Recon (1 agent, Sonnet)
  agentCount++
  const surface = await A(reconPrompt(t), {
    label: `recon:${t.name}`, phase: 'Recon', schema: SURFACE_SCHEMA, model: 'sonnet', agentType: 'classifier',
  }).catch(() => null)
  if (!surface) {
    return { system: t.name, recommended_criticality: crit, recommended_cadence: 'unknown',
      cadence_rationale: 'recon agent failed; re-run this system individually.', cost_note: `~${agentCount} agents`,
      next_due: 'reassess', log_row: `| ${today} | ${t.name} | RECON-FAILED | - | - | reassess |`,
      summary: 'Recon failed; no assessment produced.', confirmed: [] }
  }

  // Assess (fan out dimensions, throttled; model scales with criticality)
  const dimResults = await parallel(dims.map((d) => async () => {
    agentCount++
    return A(assessPrompt(t, surface, d), {
      label: `assess:${t.name}:${d}`, phase: 'Assess', schema: FINDINGS_SCHEMA,
      model: (d === 'injection-input' || d === 'authn-authz') && crit !== 'Low' ? model : (crit === 'Critical' ? 'opus' : 'sonnet'),
      agentType: 'claude',
    }).catch(() => null)
  }))
  const candidates = dimResults.filter(Boolean).flatMap((r) => (r.findings || []).map((f) => ({ ...f, dimension: r.dimension })))

  // Verify (adversarial, votes scale with criticality + severity)
  const verified = await parallel(candidates.map((f) => async () => {
    const votes = votesFor(crit, f.severity)
    const verdicts = await parallel(Array.from({ length: votes }, (_, k) => async () => {
      agentCount++
      return A(verifyPrompt(t, f), {
        label: `verify:${t.name}:${(f.title || '').slice(0, 24)}#${k + 1}`, phase: 'Verify', schema: VERDICT_SCHEMA,
        model: (f.severity === 'C' || f.severity === 'H') && crit !== 'Low' ? 'opus' : 'sonnet',
        agentType: 'claude',
      }).catch(() => null)
    }))
    const ok = verdicts.filter(Boolean)
    if (!ok.length) return null
    const reals = ok.filter((v) => v.real)
    const survives = reals.length >= Math.ceil(ok.length / 2) // majority (single vote => that vote)
    if (!survives) return null
    // adopt the highest adjusted severity among the confirming votes
    const rank = { C: 3, H: 2, M: 1, L: 0 }
    const sev = reals.map((v) => v.adjusted_severity).sort((a, b) => rank[b] - rank[a])[0] || f.severity
    return { title: f.title, severity: sev, where: f.where, exploit: f.exploit }
  }))
  const confirmed = verified.filter(Boolean)

  // Score + cadence (1 agent, Opus)
  const worstSev = ['C', 'H', 'M', 'L'].find((s) => confirmed.some((f) => f.severity === s)) || null
  const prior = cadencePrior(crit, t.exposure, worstSev, agentCount)
  agentCount++
  const scored = await A(scorePrompt(t, confirmed, prior, agentCount), {
    label: `score:${t.name}`, phase: 'Score', schema: ASSESSMENT_SCHEMA, model: 'opus', agentType: 'claude',
  }).catch(() => null)

  if (!scored) {
    // deterministic fallback if the scorer dies: still return a usable result
    const counts = confirmed.reduce((a, f) => (a[f.severity] = (a[f.severity] || 0) + 1, a), {})
    return { system: t.name, recommended_criticality: crit, recommended_cadence: prior.costAdjusted,
      cadence_rationale: `scorer failed; deterministic prior (risk ${prior.risk}/17).`,
      cost_note: `~${agentCount} agents (${model} tier for depth)`, next_due: `${prior.costAdjusted} from ${today}`,
      log_row: `| ${today} | ${t.name} | ${dims.join('+')} | ${(counts.C||0)}C/${(counts.H||0)}H/${(counts.M||0)}M/${(counts.L||0)}L | ${surface.drift} | ${prior.costAdjusted} |`,
      summary: `${confirmed.length} confirmed finding(s); scorer unavailable, used deterministic cadence.`, confirmed }
  }
  return { ...scored, system: scored.system || t.name, confirmed: scored.confirmed?.length ? scored.confirmed : confirmed }
}

// ---- run -------------------------------------------------------------------
if (!targets.length) {
  log('No targets provided; nothing to assess.')
  return { assessments: [] }
}
log(`Assessing ${targets.length} system(s): depth + votes + model tier scale with criticality; global cap ${MAX_CONC} concurrent agents.`)

// Pipeline: each system flows recon -> assess -> verify -> score independently,
// no barrier between systems (a Critical system's deep pass overlaps a Low
// system's light pass). assessSystem owns its own internal fan-out + throttle.
const assessments = await pipeline(targets, (t) => assessSystem(t))

return { assessments: assessments.filter(Boolean) }
