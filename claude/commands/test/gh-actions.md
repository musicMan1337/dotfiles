---
name: test:gh-actions
description: Live-test GitHub Actions workflow changes BEFORE merging, using disposable side-effect-free trigger copies. Creates test-* copies of the changed workflows with workflow_dispatch triggers and stubbed side effects, runs them on the branch until green, then deletes the copies pre-merge. Triggers on, test workflow, test gh actions, test github actions, verify workflow before merge, will this break the tag release, workflow dry run, test the release workflow, test ci changes, /test:gh-actions.
---

# /test:gh-actions

Answer "will this workflow change break the real trigger?" (tag release, merge to master, schedule) BEFORE merging, by running a disposable copy that cannot cause side effects.

## Procedure

### 1. Scope

Diff the branch vs its base for `.github/workflows/`. List each changed workflow and its real triggers (push tags, release, schedule, workflow_call, etc.). Confirm with the user which ones to test if more than one changed.

### 2. Create disposable copies

For each workflow under test, write `.github/workflows/test-<name>.yml`:

- **Trigger:** `workflow_dispatch` only; drop all real triggers.
- **Marking:** `run-name: "TEST COPY, <name>, do not merge"` and a header comment saying the same.
- **Stub every side-effecting step:** deploys, tag/release creation, registry pushes, attestation/SBOM publication, notifications, anything that writes outside the run. Replace each with an `echo` of what would have executed. Keep build/lint/test/compile steps real; those are what you're validating.
- **Secrets:** keep permissions/secret usage identical UNLESS the secret only fed a stubbed step; then drop that secret from the copy too.

Stub first, run second: a copy must be incapable of side effects even if it unexpectedly goes green.

### 3. Run

Commit the copies via /git:commit, push, then:

```bash
gh workflow run test-<name>.yml --ref <branch>
gh run watch          # or: gh run view <id> --log-failed
```

### 4. Iterate until green

Fix the REAL workflow file, mirror the fix into the copy, rerun. The real file stays the source of truth; never let the copy drift ahead of it.

If a failure only reproduces in the real trigger context (e.g. tag metadata, release payload), simulate with a disposable tag on a throwaway branch and delete both afterward.

### 5. Tear down (not optional)

Delete every `test-*.yml` copy (commit via /git:commit) before the PR merges. Final check: diff the branch's `.github/workflows/` against base and confirm only the intended workflow changes remain.

## Guardrails

- NEVER add `workflow_dispatch` to the real release/tag workflow just to make it testable; only the copy gets it.
- NEVER trigger the real release/tag workflow as a "test".
- Copies are visible to reviewers and other triggers the moment they're pushed; keep them obviously marked and short-lived.
- If the repo restricts who can run workflows or requires environment approvals, surface that instead of working around it.
