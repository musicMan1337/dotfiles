---
name: factory:patrol:github
model: opus
description: GitHub patrol mode. Scans issues, CI failures, PR reviews, and Dependabot alerts. Triages and dispatches auto-fixes or starter specs. Designed for /loop. Triggers on: patrol github, github patrol, check github, scan github, check ci, check prs
---

# Factory Patrol — GitHub Mode

Read `factory/patrol/SKILL_BASE.txt` and internalize the shared lifecycle before proceeding. This mode extends the base with GitHub-specific scanning, triage, and dispatch.

## Constants

```
STATE_FILE = "github-state.json"
```

## State Schema

Extends the base `last_run` with GitHub-specific tracking:

```json
{
  "last_run": "ISO-8601 | null",
  "processed": {
    "<source>:<id>": {
      "disposition": "fixed|spec-created|skipped|deferred",
      "summary": "one line",
      "timestamp": "ISO-8601",
      "branch": "factory/patrol-fix-42 (if applicable)",
      "pr": null
    }
  },
  "ci_failure_counts": {
    "<workflow>:<branch>": { "count": 2, "first_seen": "ISO-8601" }
  }
}
```

## Mode Phases

### Phase 1 — Scan Sources

Spawn **Haiku subagents** in parallel to check each available source. Pass each subagent the list of already-processed IDs so it can filter them out before returning.

**Sources** (check what's available via `gh` — skip sources that error):

1. **GitHub Issues** — `gh issue list --state open --limit 20 --json number,title,labels,body,createdAt`
   Look for: bugs, tasks assigned to repo owner, issues with recent activity

2. **CI Failures** — `gh run list --status failure --limit 10 --json databaseId,displayTitle,conclusion,headBranch,createdAt`
   Track failure counts in `ci_failure_counts` — only surface failures that appear **2+ times** for the same workflow+branch

3. **PR Review Comments** — `gh pr list --state open --limit 10 --json number,title,reviewDecision,headRefName`
   Look for: PRs with `CHANGES_REQUESTED` or unresolved comment threads

4. **Dependabot/Security** — check for open Dependabot PRs via `gh pr list --author 'app/dependabot'`

Each subagent returns structured findings:
```json
[{ "source": "issues", "id": "issues:42", "title": "...", "severity": "high|medium|low", "body_summary": "..." }]
```

### Phase 2 — Triage

For each new finding, classify:

| Classification | Criteria | Action |
|---|---|---|
| **Auto-fix** | Clear bug with obvious fix, test failure with clear cause, small dependency update | Dispatch fix agent |
| **Spec-needed** | Feature request, complex bug, architectural change, unclear scope | Create starter spec |
| **Defer** | Low priority, unclear requirements, needs human decision | Log and skip |
| **Noise** | Stale issues, duplicates, already resolved upstream | Mark processed, skip |

### Phase 3 — Dispatch

**For auto-fix items:**
- Create a branch: `factory/patrol-fix-<issue-number>` or `factory/patrol-fix-<slug>`
- Spawn a subagent with the fix context — it should: understand the issue, make the fix, run tests if available
- Commit via `/git:commit`
- Do **NOT** create PRs — just commit to the branch. Log the branch name in state.
- If the fix subagent fails or expresses uncertainty, reclassify as "deferred"

**For spec-needed items:**
- Write a starter spec to `.factory/specs/<issue-number>-<slug>.md`
- Include: problem statement, relevant context from the issue, suggested approach, open questions
- This is a *starter spec*, not a full spec — it's input for a human or `/factory:pipeline` later

## Notify Threshold

- `action-needed` severity if auto-fixes were dispatched
- `info` severity if only specs were created
- Silent (no notify) if only deferrals/noise

## Hard Constraints

- **Never auto-fix:** auth/security code, payment logic, database migrations, CI/CD config, environment variables, secrets, deployment scripts
- **Cap auto-fixes at 3 per run.** If more qualify, fix the 3 highest-severity ones and defer the rest. You'll run again soon.
- **Default branch CI failures are higher priority** than feature branch failures.
- **Branches without PRs are intentional.** Patrol creates branches to preserve work, but PR creation is a human decision or a `/factory:pipeline` decision. No PR spam.
- **Starter specs are intentionally incomplete.** They capture the problem and context, not the full solution. Don't over-spec — that's pipeline's job.

## Gotchas

- **CI failures can be transient.** That's why you track `ci_failure_counts` and only act after 2+ occurrences. A single red run is not actionable.
- **GitHub API rate limits.** The `gh` CLI handles auth, but don't make 100 API calls per patrol. The scan subagents should batch queries.
- **This mode requires a GitHub remote.** If `gh` commands fail (no remote, no auth), skip gracefully and log the error. Don't crash.
