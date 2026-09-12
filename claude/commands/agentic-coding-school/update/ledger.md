# Mined videos ledger

Written by `/agentic-coding-school:update`. One row per video whose transcript was mined, rejects included; a video listed here is never re-mined. The course MCP is read-only, so this is the only record of what has been reviewed (watch status in the web UI is a separate axis).

No transcript text here: paid course material, public repo.

| Mined | Class | Video | Verdict | Note |
|-------|-------|-------|---------|------|
| 2026-08-17 | claude-code | Nested Subagents | ADOPT | video's "off by default" claim was true only for v2.1.217-218; docs confirm depth 3 default on 2.1.234, and the Agent tool is withheld at the cap rather than erroring |
| 2026-08-17 | claude-code | Cross Session Talk | ADOPT | named peer sessions (`claude -n`) + SendMessage for work outliving a subagent |
| 2026-08-17 | fundamental-techniques | Unconstraining the Exploration Space | ADOPT | `--safe-mode` for ideation outside the harness's own conventions |
| 2026-08-17 | advanced-techniques | Point Fixes vs Architectural Fixes | ADAPT | same-class sweep + ranked least-to-most-invasive ladder on repeat bugs |
| 2026-08-17 | loopy-ai | Improving the Loop | ADAPT | mine session transcripts of a skill's own runs to grow its gotchas; shipped as harness:skill-feedback |
| 2026-08-17 | loopy-ai | Creating the Skill | ADAPT | GIF evidence for UI flows shipped into the exercised rule; rejected blast-radius auto-merge and cross-vendor review |
| 2026-08-17 | advanced-techniques | Score Before You Spend | REJECT | impact x opportunity already in security:assess-attack-surface; generic ranker is project work |
| 2026-08-17 | advanced-techniques | Deep Bug Hunting | REJECT | 98-agent fan-out; economics die under the 4/6 CryptoGuard cap |
| 2026-08-17 | fundamental-techniques | Evaluating Code Review Tools | REJECT | independent-reviewer principle already in plan-auditor/security-auditor |
| 2026-08-17 | loopy-ai | Testing the Loop | REJECT | watch-until-quiet PR loop is project workflow; self-critique pass is unpriced scaffolding |
| 2026-08-17 | loopy-ai | Feedback Channels | REJECT | agent capability-request channel needs long autonomous loops to pay off; revisit if that changes |
| 2026-08-17 | loopy-ai | Automated Maintenance | REJECT | scheduled repo-maintenance routines are per-repo work, not harness rules |
| 2026-08-17 | workflows | Agent Browser to Skill | REJECT | capture-endpoints-then-generate-skill is a good pattern with no current target site |
| 2026-08-17 | codex | @ over Symlinking | REJECT | solves cross-tool AGENTS.md/CLAUDE.md divergence; single-tool setup has no such problem |
| 2026-08-17 | codex | Symlinking Skills | REJECT | whole-dir commands symlink already does this; front-matter dialect clash needs a second tool |
| 2026-09-12 | fundamental-techniques | Rewriting Agent Skills | ALREADY HAVE | model-upgrade step 2 already runs the scaffold-bypassed task vs scaffolded and compares; video's skill-disable env var unverified, not needed |
| 2026-09-12 | loopy-ai | Model Choice in Loops | REJECT | TIERS.md already says prefer cheap tier, promote on observed misses; benchmark cites stale models; belongs to the next model-upgrade run, not a rule |
| 2026-09-12 | slack-agents | Task vs Ownership Delegation | REJECT | assumes an always-on Slack listener; ownership idea already is ebacon:checklist |
| 2026-09-12 | fundamental-techniques | Build It Twice | REJECT | 2x build cost, per-project judgment call; its retrospective half falls out of the decision log for free |
| 2026-09-12 | fundamental-techniques | Static & Dynamic Analysis | ADAPT | lint/test/hook-over-prose gate added to docs:update; harness-level version already in Harness Engineering Conventions |
| 2026-09-12 | fundamental-techniques | Runtime Context | ADOPT | parameter-bump smell (timeout/threshold/retry/magic number with no mechanism is not a root cause) added to "Bug reports: investigate first" |
| 2026-09-12 | fundamental-techniques | Invariants and Surfaces | REJECT | docs/invariants/ is a project-repo convention (would live in Viper), not a claude/ file |
| 2026-09-12 | fundamental-techniques | Code & Agent Blast Radius | ADAPT | incident-history pointer (vault incidents/) added to blast-radius; agent-access worst case and risk-scaled verify already in env-lockdown, harden-gate, blast-radius step 4 |
| 2026-09-12 | fundamental-techniques | Architectural Decision Records | ADOPT | enforced_by / touches / Revisit-if added to docs:create ADR path; auto-writing ADRs unprompted rejected on the scope norm |
| 2026-09-12 | fundamental-techniques | Implementation Notes & Decision Logs | ADAPT | live `## Decisions` section in the plan file via spec:implement + viper-worktree, surfaced by dev:wrapup |
| 2026-09-12 | fundamental-techniques | Overview of Verification Environments | ADAPT | diff-to-user-reachable-path enumeration before verify-viper drives anything; undriven paths named in the report |
| 2026-09-12 | fundamental-techniques | Setting Up Verification Environments | REJECT | verifier-of-verifiers deferred until a run passes an undriven flow; seed subagent already dev:sql pre-scripts; image pre-bake is Viper repo work |
