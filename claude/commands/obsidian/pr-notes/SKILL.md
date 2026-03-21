---
name: obsidian:pr-notes
model: haiku
description: Create PR review notes in Obsidian from GitHub reviews. Triggers on: pr notes, pr review notes, log pr review, review notes, what prs did I review
---

# PR Review Notes

Fetch PR review data from GitHub and write structured notes to Obsidian. One file per day containing all PRs reviewed that day.

## Input

**Request:** $ARGUMENTS

- No args → fetch all PRs reviewed by me in the last 24 hours
- A PR number (e.g., "1234") → fetch that specific PR from the current repo
- A PR number + repo (e.g., "1234 eBaconInc/Viper") → fetch from a specific repo
- A date (e.g., "2026-03-18" or "yesterday") → fetch reviews from that day

## Step 1 — Determine the target date

Resolve the target date from the input. Default to today if no date is specified.

## Step 2 — Fetch PR data

Run the extraction script:

```bash
node ~/.claude/commands/obsidian/pr-notes/lib/fetch-reviews.js [PR_NUMBER] [OWNER/REPO]
```

This returns JSON with PR metadata, review state, comments, files changed, etc.

If the script returns empty results (common for approval-only reviews with no comments), fall back to the GitHub API directly:

1. Search for PRs reviewed by the user on the target date:
```bash
gh api "search/issues?q=reviewed-by:@me+type:pr+updated:>=YYYY-MM-DD" --jq '.items[] | ...'
```

2. For each PR, fetch review details:
```bash
gh api "repos/OWNER/REPO/pulls/NUMBER/reviews" --jq '.[] | select(.user.login == "USERNAME" and (.submitted_at | startswith("YYYY-MM-DD")))'
```

3. For PRs with CHANGES_REQUESTED or review comments, also fetch inline comments:
```bash
gh api "repos/OWNER/REPO/pulls/NUMBER/comments" --jq '.[] | select(.user.login == "USERNAME" and (.created_at | startswith("YYYY-MM-DD")))'
```

Skip the user's own PRs (where author matches the current user).

## Step 3 — Check existing notes and write

### File naming

One file per day: `reviews/YYYY-MM-DD.md`

### Check if the day's file already exists

```bash
source ~/.zprofile && obsidian read path="reviews/YYYY-MM-DD.md"
```

**If the file exists:**
- Read it and check which PR numbers are already logged
- Only append new PRs that aren't already in the file
- Use `obsidian create ... overwrite` with the merged content

**If no file exists:**
- Create it with all reviews for that day

### Content format

The file lists all PRs reviewed that day. Each PR is a section separated by `---`:

```markdown
## #<number> — <short-title>
**Author:** <author> | **Status:** <APPROVED/CHANGES_REQUESTED/COMMENTED> | **Files:** <count>
**Branch:** <head> → <base>
<url>

<review body if any>

<inline comments if any, as bullets with file:line prefix>
```

Example:
```markdown
## #9248 — Resource budgeting system
**Author:** Evilnames | **Status:** CHANGES_REQUESTED | **Files:** 33
**Branch:** Alex/Resource → master
https://github.com/TAGEmployerServices/Viper/pull/9248

Needs refactoring: no .css files, no .js files, use ebacon-ui components, move to react/app/domains.

---
## #9270 — Task Match validation
**Author:** thnlsn | **Status:** APPROVED | **Files:** 13
**Branch:** Thomas/336615-RateMgmtTaskValidation → master
https://github.com/TAGEmployerServices/Viper/pull/9270

Revert the package lock to master's version.
```

**Ordering:** List CHANGES_REQUESTED PRs first (most notable), then COMMENTED, then APPROVED. Within each group, order by PR number descending (newest first).

**Brevity rules:**
- If the review body is empty and there are no inline comments, omit the body section entirely (the status line is sufficient)
- For inline comments, prefix with the file path: `- \`path/to/file:123\` — comment text`

## Step 4 — Report

Show the user a summary of how many PRs were logged and any notable reviews (changes requested, detailed feedback).

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Don't duplicate PRs.** When appending to an existing day file, check PR numbers already present.
- **gh CLI auth required.** If `gh` fails with auth errors, tell the user to run `gh auth login`.
- **Large PRs:** Show file count, not individual file names.
- **Empty reviews:** Approval-only reviews with no comments are still logged — the status line captures the action.
- **Skip own PRs:** Don't log reviews on the user's own PRs (self-approvals, etc.).
