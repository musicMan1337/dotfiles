---
name: dev:wrapup
description: End-of-task close-out chain, one command instead of the hand-typed ritual. Commits via /git:commit, pushes, opens a PR via /git:pr if none exists, leaves the case note (Viper branch, posts it to the prod case via the /case-note PR-comment CI action; otherwise prints a pithy sentence), logs the work via /obsidian:standup-add, and optionally tears down the Viper worktree. Triggers on, wrapup, wrap up, wrap it up, close out, close this out, ship and log, commit push pr standup-add, commit push standup-add, commit push pr, commit push standup, standdup-add, /dev:wrapup.
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

### 3. PR (with soft review gate)

Skip if `no-pr` or the branch is `master`/`main`. Otherwise:

- **Soft review gate (offer, never block).** Unless the diff is trivial (docs/config/test-only) or the user already reviewed this session, offer before the PR goes up (numbered): 1. run `/code-review` on the branch diff first, 2. skip and open the PR. On 1, run it and surface findings; the user decides fix-now vs ship. A declined or skipped review never stops the chain.
- Then `gh pr view --json url,state` for the current branch:
  - Open PR exists: reuse it, print the URL.
  - None (or closed): invoke `/git:pr`.

### 4. Case note

If the branch matches `<Name>/<CaseId>-<desc>`, leave the case note; otherwise skip silently. Depends on step 3 having produced a PR.

- **Viper PR (the branch has a PR in `TAGEmployerServices/Viper`):** post the note to the prod case via the repo's case-note CI action, do NOT print a paste-ready sentence. Comment the pragma on the PR:
  ```bash
  gh pr comment <pr-number> --body-file <file>   # body starts with: /case-note <CaseId> <note>
  ```
  `.github/workflows/manual-case-note.yml` (trigger: an `issue_comment` whose body starts with `/case-note`, gated to org OWNER/MEMBER/COLLABORATOR) parses `/case-note <CaseId> <note text>` and writes the note to the prod Viper case via `tagemployerservices/actions/case-note`. Rules: the comment body MUST start with `/case-note` (the workflow regex anchors on it); the note is 1-2 pithy outcome-focused sentences, no file lists (multiline is allowed). Use `--body-file` (a scratchpad file), never inline `--body`, so apostrophes/backslashes in the note don't get mangled by the shell. This writes to a real prod case, a genuine side effect, but the user opted into it by invoking wrapup for a Viper case branch, so do it without re-prompting. After posting, confirm the action fired: `gh run list --workflow manual-case-note.yml --limit 2` should show a `success` run (a second `skipped` run is normal, the bot's own ✅ reply re-triggers and no-ops); the bot also reacts 🚀 and replies `✅ Case note added to Case-<CaseId>`. If the run failed, surface it.
- **No Viper PR (`no-pr`, `master`, or a non-Viper repo without the action):** fall back to printing 1-2 pithy sentences labeled `Case note (<CaseId>):`, outcome-focused, no file lists, ready to paste into the case.

### 5. Standup

Invoke `/obsidian:standup-add`, passing through any date token and free text from the args. If standup-add already ran this session for this same work, do not invoke it again; note that it's already logged.

### 6. Cleanup (only with the `cleanup` arg)

Inside a Viper worktree (`pwd` under `/Users/derek/eBacon/Viper/.worktrees/`): invoke `/dev:viper-worktree-cleanup`. Anywhere else: skip with a one-line note.

### 7. Hand back

One short block: branch, new commit hash(es), PR URL, case-note status (posted to the case via the PR pragma with the run/confirmation link, or the printed sentence for non-Viper), standup status, cleanup status. No prose recap beyond that.

## Gotchas

- **Sequencing is the point.** Do not parallelize the steps; commit must land before push, push before PR.
- **A failed step stops the chain.** Report which step failed and what's left undone; never continue past a failed commit or push.
- **SQL batches:** if the session's work touched the eBacon SQL repo, the close-out for that part is `/dev:sql` (its own commit/push/build flow). Run it before step 4 so the case note can mention the script path.
- **Typo tolerance:** "standdup-add" and similar near-misses of the old ritual mean this command; do not fall back to guessing individual skills.
