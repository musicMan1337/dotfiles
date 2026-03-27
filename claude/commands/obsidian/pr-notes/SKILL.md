---
name: obsidian:pr-notes
model: haiku
description: Create PR notes in Obsidian from GitHub reviews and authored PRs. Triggers on: pr notes, pr review notes, log pr review, review notes, what prs did I review, my prs
---

# PR Notes

Fetch PR data from GitHub and write structured notes to Obsidian. One file per day containing all PRs reviewed AND all PRs authored by the user that day.

## Input

**Request:** $ARGUMENTS

- No args → fetch all PRs reviewed by me AND authored by me in the last 24 hours
- A PR number (e.g., "1234") → fetch that specific PR from the current repo
- A PR number + repo (e.g., "1234 eBaconInc/Viper") → fetch from a specific repo
- A date (e.g., "2026-03-18" or "yesterday") → fetch reviews and authored PRs from that day

## Step 1 — Determine the target date

Resolve the target date from the input. Default to today if no date is specified.

## Step 2 — Fetch PR data

Two categories of PRs are fetched: **reviews** (PRs by others that the user reviewed) and **authored** (PRs the user opened or updated).

### 2a — Fetch reviewed PRs

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

### 2b — Fetch authored PRs

Search for PRs authored by the user that were created or updated on the target date:

```bash
gh pr list --author @me --search "updated:>=YYYY-MM-DD" --limit 50 --json number,title,url,state,headRefName,baseRefName,changedFiles,reviews,createdAt,updatedAt
```

For each authored PR, determine its review status by checking the `reviews` array for the most recent review from each reviewer (APPROVED, CHANGES_REQUESTED, COMMENTED, PENDING).

Include PRs that were **created** on the target date, or **received review activity** on the target date (new reviews, comments, approvals).

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

The file has two sections: **Authored** (PRs the user opened) and **Reviews** (PRs by others the user reviewed). Omit a section heading if there are no entries for it. Each PR is separated by `---`:

#### Authored PRs format

```markdown
# Authored

## #<number> — <short-title>
**State:** <OPEN/MERGED/CLOSED> | **Reviews:** <summary> | **Files:** <count>
**Branch:** <head> → <base>
<url>

<review activity summary — who approved, who requested changes, notable comments received>
```

**Review summary** on the status line: compact list like `2 approved, 1 changes requested` or `pending review` if no reviews yet.

**Review activity:** Below the status line, list notable review activity from that day (new approvals, change requests, comments received from others). If no activity beyond the PR being opened, omit this section.

**Ordering:** OPEN PRs first (active work), then MERGED (completed), then CLOSED. Within each group, order by PR number descending (newest first).

#### Reviewed PRs format

```markdown
# Reviews

## #<number> — <short-title>
**Author:** <author> | **Status:** <APPROVED/CHANGES_REQUESTED/COMMENTED> | **Files:** <count>
**Branch:** <head> → <base>
<url>

<review body if any>

<inline comments if any, as bullets with file:line prefix>
```

Example:
```markdown
# Authored

## #9284 — Modernize test infrastructure
**State:** OPEN | **Reviews:** pending review | **Files:** 12
**Branch:** Derek/NoCase-TestingSpecs → master
https://github.com/TAGEmployerServices/Viper/pull/9284

---

# Reviews

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

**Ordering (Reviews):** List CHANGES_REQUESTED PRs first (most notable), then COMMENTED, then APPROVED. Within each group, order by PR number descending (newest first).

**Brevity rules:**
- If the review body is empty and there are no inline comments, omit the body section entirely (the status line is sufficient)
- For inline comments, prefix with the file path: `- \`path/to/file:123\` — comment text`
- For authored PRs with no review activity that day, the status line alone is sufficient

## Step 4 — Report

Show the user a summary of how many PRs were logged and any notable reviews (changes requested, detailed feedback).

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Don't duplicate PRs.** When appending to an existing day file, check PR numbers already present.
- **gh CLI auth required.** If `gh` fails with auth errors, tell the user to run `gh auth login`.
- **Large PRs:** Show file count, not individual file names.
- **Empty reviews:** Approval-only reviews with no comments are still logged — the status line captures the action.
- **Skip own PRs in Reviews section:** Don't log self-reviews on your own PRs in the Reviews section — those PRs belong in the Authored section instead.
- **Authored vs Reviewed:** A PR should appear in only one section. If the user authored a PR, it goes in Authored (even if they also left self-review comments). If someone else authored it and the user reviewed it, it goes in Reviews.
