---
name: factory:patrol:merge
model: sonnet
description: Auto-merge patrol. Watches open PRs and merges them as soon as CI passes and they're in a mergeable state. Cross-repo. Designed for /loop. Triggers on: merge patrol, auto merge, watch prs, merge my prs, merge when ready, patrol merge
---

# Factory Patrol — Merge Mode

Read `factory/patrol/SKILL_BASE.md` and internalize the shared lifecycle before proceeding. This mode extends the base with PR merge watching — a **finite mode** that terminates when all watched PRs are merged.

## Constants

```
STATE_FILE = "merge-state.json"
DEFAULT_STRATEGY = "squash"
SAME_REPO_COOLDOWN = 30  # seconds to wait after merging before checking other PRs in the same repo
POLL_FIELDS = "number,title,url,state,mergeable,mergeStateStatus,statusCheckRollup,reviewDecision,isDraft,headRefName,baseRefName,repository"
```

## State Schema

Extends the base `last_run` with merge-specific tracking:

```json
{
  "last_run": "ISO-8601 | null",
  "strategy": "squash|merge|rebase",
  "delete_branch": true,
  "watch_list": {
    "<repo>:<pr_number>": {
      "repo": "owner/repo",
      "number": 42,
      "title": "Fix login bug",
      "url": "https://github.com/owner/repo/pull/42",
      "branch": "fix-login",
      "status": "waiting|updating|ready|merged|failed|closed|conflicts",
      "added": "ISO-8601",
      "last_check": "ISO-8601",
      "last_merge_state": "CLEAN|BLOCKED|BEHIND|DIRTY|UNKNOWN|DRAFT",
      "last_ci_state": "pending|success|failure",
      "last_review": "APPROVED|CHANGES_REQUESTED|REVIEW_REQUIRED|null",
      "update_requested_at": "ISO-8601 | null",
      "merge_attempted": false,
      "merged_at": null,
      "error": null
    }
  },
  "completed": false
}
```

## Arguments

Parse the user's input for:

- **PR identifiers** (optional): space-separated list of PR numbers or URLs
  - Bare numbers (e.g., `42 55`) — assumes current repo
  - Full URLs (e.g., `https://github.com/owner/repo/pull/42`) — extracts repo + number
  - `owner/repo#42` format — extracts repo + number
- **Flags:**
  - `--strategy squash|merge|rebase` — merge strategy (default: squash)
  - `--no-delete` — don't delete branches after merge
  - `--all` — watch ALL your open PRs (skip selection)

## Mode Phases

### Phase 1 — Build Watch List

**If watch list already exists in state** (resume/loop run): skip to Phase 2. The watch list is set once and doesn't change between loop iterations.

**If PR numbers provided as args:**

For each PR identifier, validate it exists and is open:
```bash
gh pr view <number> -R <repo> --json number,title,url,state,headRefName,mergeable,mergeStateStatus,statusCheckRollup,reviewDecision,isDraft
```
Add each valid, open PR to the watch list. Warn on any invalid/closed PRs.

**If no args provided (interactive discovery):**

1. Search for all your open PRs across repos:
   ```bash
   gh search prs --author=@me --state=open --json number,title,repository,url,updatedAt
   ```

2. If `--all` flag: add everything to the watch list.

3. Otherwise, present the list grouped by repo and ask the user which to watch:
   ```
   Found 8 open PRs across 3 repos:

   owner/repo-a:
     #42  Fix login validation          (updated 2h ago)
     #55  Add rate limiting             (updated 1d ago)

   owner/repo-b:
     #12  Update dependencies           (updated 30m ago)

   owner/repo-c:
     #78  Refactor auth middleware       (updated 3d ago)
     #79  Add unit tests for auth       (updated 3d ago)
     #80  Fix flaky CI test             (updated 5d ago)
     #81  Update README                 (updated 1w ago)
     #82  Bump node version             (updated 1w ago)

   Which PRs should I watch? (enter numbers, "all", or repo name for all in that repo)
   ```

4. After selection, populate the watch list in state with full PR details by fetching each one:
   ```bash
   gh pr view <number> -R <repo> --json <POLL_FIELDS>
   ```

### Phase 2 — Check Merge Readiness

For each PR in the watch list where `status = "waiting"` or `status = "updating"`:

**Respect the same-repo cooldown.** If another PR in the same repo was merged this run, check the timestamp. If fewer than 30 seconds have elapsed since that merge, **sleep until the cooldown expires** before querying. This gives GitHub time to recalculate merge states after the base branch changed.

**For PRs with `status = "updating"`:** These had an update-branch request triggered last run. Check if the update completed — CI may still be running on the new merge commit. Query the PR and evaluate normally.

Query current state:
```bash
gh pr view <number> -R <repo> --json mergeable,mergeStateStatus,statusCheckRollup,reviewDecision,isDraft,state
```

**Parse merge readiness:**

| Field | Ready Value | Meaning |
|---|---|---|
| `state` | `OPEN` | PR is still open (not closed/merged externally) |
| `isDraft` | `false` | Not a draft PR |
| `mergeable` | `MERGEABLE` | No merge conflicts |
| `mergeStateStatus` | `CLEAN` | All requirements met — merge button is green |
| `statusCheckRollup` | all `SUCCESS` or `NEUTRAL` | CI passed |
| `reviewDecision` | `APPROVED` or empty (no required reviews) | Reviews satisfied |

**A PR is ready to merge when `mergeStateStatus = "CLEAN"`.** This is the single authoritative field — GitHub computes it from all branch protection rules, CI status, and review requirements. Don't second-guess it.

**Update state for each PR:**
- If `state = "MERGED"` or `state = "CLOSED"` → mark as `merged` or `closed` (handled externally)
- If `mergeStateStatus = "CLEAN"` → mark as `ready`
- If `mergeStateStatus = "BEHIND"` → proceed to Phase 3 (Update Branch)
- If `mergeStateStatus = "DIRTY"` → proceed to Phase 3 (Conflict Resolution)
- Otherwise → keep as `waiting`, update `last_merge_state`, `last_ci_state`, `last_review`

### Phase 3 — Update Behind Branches & Resolve Conflicts

Process PRs that need branch updates or have conflicts. Handle repos sequentially — one update at a time per repo.

**For PRs with `mergeStateStatus = "BEHIND"` (branch needs update):**

Trigger GitHub's "Update branch" via the API — this merges the base branch into the PR branch server-side:
```bash
gh api repos/{owner}/{repo}/pulls/{number}/update-branch --method PUT -f expected_head_sha="{current_head_sha}"
```

Get the current head SHA first:
```bash
gh pr view <number> -R <repo> --json headRefOid --jq '.headRefOid'
```

**On success:**
- Set `status = "updating"`, `update_requested_at = now`
- The PR will need CI to re-run on the new merge commit. Next loop iteration picks it up in Phase 2.

**On failure (conflicts detected):**
The update-branch API returns a conflict error when the merge can't be done cleanly. This is functionally the same as `mergeStateStatus = "DIRTY"`.

**For PRs with `mergeStateStatus = "DIRTY"` (merge conflicts):**

1. **Attempt simple conflict resolution** by spawning a subagent:
   - Clone/checkout the PR branch locally
   - Merge the base branch and inspect conflicts
   - **Simple conflicts** (auto-resolvable or trivial — e.g., lockfile conflicts, adjacent-line changes, deleted-vs-modified where the deletion is clearly correct): resolve, commit via `/git:commit`, push
   - **Complex conflicts** (logic conflicts, both sides substantially changed the same code, anything requiring judgment): abort

2. **On successful resolution:**
   - Push the resolved merge commit
   - Set `status = "updating"` — CI needs to re-run
   - Log: `Resolved conflicts for <repo>#<number>: <description of resolution>`

3. **On failed resolution (complex conflicts):**
   - Set `status = "conflicts"`
   - Invoke `/factory:notify` immediately:
     ```
     summary: "PR {repo}#{number} has merge conflicts that need manual resolution"
     severity: action-needed
     source: patrol
     links: ["{pr_url}"]
     details: "Conflicting files: {file list}. Could not auto-resolve — logic conflicts in {description}."
     ```

### Phase 4 — Merge Ready PRs

Process repos sequentially. Within each repo, merge PRs one at a time with a **30-second cooldown** between merges.

**For each repo with ready PRs:**

1. Pick the next PR where `status = "ready"`
2. Merge:
   ```bash
   gh pr merge <number> -R <repo> --<strategy> --delete-branch
   ```
   (Omit `--delete-branch` if `delete_branch = false` in state.)

3. **On success:**
   - Mark `status = "merged"`, set `merged_at`
   - Log: `Merged <repo>#<number>: <title> via <strategy>`
   - **If more PRs in this repo are `ready`:** sleep 30 seconds, then re-check their `mergeStateStatus` before merging. The base branch just changed — their status likely shifted to `BEHIND`.
   - **If more PRs in this repo are `waiting`:** sleep 30 seconds, then re-check them too. They may now be `BEHIND` and need Phase 3 treatment.

4. **On failure:**
   - Set `merge_attempted = true`, `error = "<error message>"`
   - If error indicates the PR is no longer mergeable (race condition): reset `status = "waiting"` to retry next loop
   - If error indicates a permanent failure (PR closed, branch deleted, permissions): mark `status = "failed"`

**After processing all repos:** any PRs that transitioned to `BEHIND` from the cooldown re-check should be handled by looping back through Phase 3 (Update Branch) within the same run. Don't defer to the next loop iteration if you can handle it now.

### Phase 5 — Check Completion

Count statuses across the watch list:

- **All `merged` or `closed`** → set `completed = true` in state. This signals the loop to stop.
- **Some `waiting`, `updating`, or `BEHIND`** → will check again next loop iteration.
- **Any `conflicts`** → already notified. Include in log. Don't block completion of others.
- **Any `failed`** → include in notification but don't block completion of others.

## Notify Threshold

- `info` severity for each PR merged this run (batch into one notification)
- `action-needed` severity if a PR fails to merge permanently
- `info` severity when all PRs in watch list are complete: "All {N} PRs merged. Patrol complete."
- Silent on no-op (no state changes)

## Log Format

```
## Merge Patrol — YYYY-MM-DD HH:MM
- Watched: {N} | Merged this run: {N} | Waiting: {N} | Failed: {N}
- Merges: {repo}#{number} ({strategy}), ...
- Result: {merged-all | merged-some | waiting | no-op}
```

## Completion & Loop Termination

This is a **finite mode**. When `completed = true` in state:
- The final notification says all PRs are merged
- Subsequent loop runs detect `completed = true` and exit immediately (no API calls)
- The user can clear the state to start a new watch session: delete `merge-state.json` or run with new args

## Hard Constraints

- **Never merge draft PRs.** Even if they somehow pass all checks.
- **Never force-merge.** If `mergeStateStatus != "CLEAN"`, wait. Never use `--admin` to bypass branch protections.
- **Never merge PRs you didn't author.** The search uses `--author=@me`, but validate on each merge that the PR author matches.
- **Respect merge strategy.** Use the configured strategy consistently. Don't switch strategies mid-session.
- **One merge at a time per repo.** If watching multiple PRs in the same repo, merge them sequentially with a 30-second cooldown between merges. One merge changes the base branch and invalidates the merge state of remaining PRs.
- **Use GitHub's update-branch API for BEHIND PRs.** Don't locally rebase and force-push. The API endpoint `PUT /repos/{owner}/{repo}/pulls/{number}/update-branch` does exactly what the "Update branch" button does — GitHub manages it server-side.
- **Only auto-resolve trivial conflicts.** Lockfile regeneration, adjacent-line changes, deleted-vs-modified where intent is clear. Anything involving logic or both sides substantively editing the same code → notify and stop. A bad conflict resolution is worse than no resolution.

## Gotchas

- **`mergeStateStatus` is the source of truth.** Don't build your own merge-readiness logic from individual fields. GitHub already computes this. `CLEAN` = merge button is green. Everything else = wait.
- **PRs can be merged externally.** If someone clicks merge on GitHub between your checks, `state` will be `MERGED`. Handle gracefully — mark as merged, don't error.
- **Rate limits matter more here.** Each PR check is an API call. With 10 PRs across 5 repos, that's 10 calls per loop iteration. At 10-minute intervals, this is fine. Don't run this at 1-minute intervals with 50 PRs.
- **Cross-repo needs auth.** `gh` must have access to all repos in the watch list. If a repo errors, mark those PRs as `failed` with an auth error, don't crash the whole patrol.
- **Branch deletion can fail.** If `--delete-branch` fails (branch protection on the branch itself), the merge still succeeded. Log the warning, don't mark as failed.
- **`statusCheckRollup` can be empty.** Some repos have no required checks. That's fine — `mergeStateStatus` still reflects the correct state.
- **Squash merge is default** because it's the most common team preference. If a repo requires a specific strategy via branch protection, `gh pr merge` will error — the user needs to set `--strategy` correctly.
- **The watch list is immutable after creation.** New PRs opened after the patrol starts are NOT automatically added. The user starts a new session for those. This keeps the scope bounded and the completion condition clear.
- **The 30-second cooldown is critical for same-repo multi-PR merges.** Merging one PR updates the base branch. Other PRs in that repo instantly become `BEHIND`. GitHub needs a few seconds to recalculate `mergeStateStatus`. Without the cooldown, you'll read stale state and either fail to merge or miss the BEHIND transition.
- **Update-branch API requires `expected_head_sha`.** Always fetch the current head SHA immediately before calling. If the SHA is stale (someone pushed to the branch between your fetch and the API call), the API returns an error. Retry once with a fresh SHA; if it fails again, defer to next loop.
- **CI re-runs after update-branch.** The update creates a new merge commit, which triggers CI. The PR won't be `CLEAN` until CI passes again. Set status to `updating` and wait — don't try to merge immediately after an update.
- **Conflict resolution runs locally.** This is the one phase that needs a local clone of the repo. If the working directory IS the repo, use it directly. If cross-repo, clone to a temp directory, resolve, push, and clean up. Keep conflict resolution subagents sequential per repo.
- **DIRTY can mean two things.** Either there are actual merge conflicts (files conflict), or the branch has diverged in a way GitHub can't auto-merge. The update-branch API will fail on true conflicts. Only then do you attempt local resolution.
