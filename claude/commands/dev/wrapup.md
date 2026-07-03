---
name: dev:wrapup
description: End-of-task close-out chain, one command instead of the hand-typed ritual. Commits via /git:commit, pushes, opens a PR via /git:pr if none exists, prints a pithy case-note sentence when the branch has a case ID, logs the work via /obsidian:standup-add, and optionally tears down the Viper worktree. Triggers on, wrapup, wrap up, wrap it up, close out, close this out, ship and log, commit push pr standup-add, commit push standup-add, commit push pr, commit push standup, standdup-add, /dev:wrapup.
---

# /dev:wrapup

Replaces the "commit push pr standup-add [cleanup]" chain. Run the steps in order; skip any step whose precondition is absent and say so in one line. Each sub-skill keeps its own gates (lint check in /git:commit, approval gate in /obsidian:standup-add); this command sequences them, it does not bypass them.

## Args

`$ARGUMENTS` may contain, in any order:

- `cleanup` : after everything else, tear down the current Viper worktree via `/dev:viper-worktree-cleanup`.
- `no-pr` : skip the PR step.
- A date token (`yesterday`, weekday, `YYYY-MM-DD`) : passed through to `/obsidian:standup-add` as the target day.
- Any other free text : passed through to `/obsidian:standup-add` as the work description.

## Steps

### 1. Commit

`git status --porcelain`. Dirty tree: invoke `/git:commit` (the Skill, never raw `git commit`). Clean tree: skip, note "nothing to commit".

### 2. Push

Push the current branch. No upstream yet: `git push -u origin <branch>`. Never force-push, never pull/rebase to resolve a rejected push; if the push is rejected, stop the chain and report, with numbered options for how to proceed.

### 3. PR

Skip if `no-pr` or the branch is `master`/`main`. Otherwise `gh pr view --json url,state` for the current branch:

- Open PR exists: reuse it, print the URL.
- None (or closed): invoke `/git:pr`.

### 4. Case-note sentence

If the branch matches `<Name>/<CaseId>-<desc>`, print 1-2 pithy sentences describing the fix, labeled `Case note (<CaseId>):`, ready to paste into the case. Outcome-focused, no file lists. No case ID in the branch: skip silently.

### 5. Standup

Invoke `/obsidian:standup-add`, passing through any date token and free text from the args. If standup-add already ran this session for this same work, do not invoke it again; note that it's already logged.

### 6. Cleanup (only with the `cleanup` arg)

Inside a Viper worktree (`pwd` under `/Users/derek/eBacon/Viper/.worktrees/`): invoke `/dev:viper-worktree-cleanup`. Anywhere else: skip with a one-line note.

### 7. Hand back

One short block: branch, new commit hash(es), PR URL, the case-note sentence, standup status, cleanup status. No prose recap beyond that.

## Gotchas

- **Sequencing is the point.** Do not parallelize the steps; commit must land before push, push before PR.
- **A failed step stops the chain.** Report which step failed and what's left undone; never continue past a failed commit or push.
- **SQL batches:** if the session's work touched the eBacon SQL repo, the close-out for that part is `/dev:sql` (its own commit/push/build flow). Run it before step 4 so the case note can mention the script path.
- **Typo tolerance:** "standdup-add" and similar near-misses of the old ritual mean this command; do not fall back to guessing individual skills.
