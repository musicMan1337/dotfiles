---
name: obsidian:briefing
model: haiku
description: Morning briefing — show where you left off, open follow-ups, pending reviews, and draft today's standup plan. Triggers on: briefing, morning briefing, start my day, where did I leave off, what's on my plate, daily briefing
---

# Daily Briefing

Generate a morning context-restore by pulling from Obsidian notes, GitHub, and Claude session history. Then draft today's standup entry.

## Input

**Request:** $ARGUMENTS

No args needed — defaults to "brief me for today". The user might also say:
- "briefing for monday" (if catching up after a weekend)
- "what did I miss yesterday"

## Step 0 — Compute dates (MANDATORY, first action)

Do not guess the weekday. Run this before anything else to get authoritative `$TODAY` and `$YESTERDAY` (Mon→Fri handled):

```bash
today=$(date "+%Y-%m-%d"); dow=$(date "+%u"); \
  if [ "$dow" = "1" ]; then yday=$(date -v-3d "+%Y-%m-%d"); \
  elif [ "$dow" = "7" ]; then yday=$(date -v-2d "+%Y-%m-%d"); \
  else yday=$(date -v-1d "+%Y-%m-%d"); fi; \
  echo "today=$today ($(date '+%A'))"; echo "yesterday=$yday"
```

Use the printed `today` / `yesterday` values everywhere below — never substitute a guessed date.

## Step 1 — Check prior day's standup (BLOCKING)

This step gates the entire briefing. Do NOT proceed to Step 2 until resolved.

Read the prior workday's standup file:

```bash
source ~/.zprofile && obsidian read path="standup/$yday.md"
```

**A completed standup is just a title and bullet points — no sections like `## Today`, `## Completed`, `## Yesterday`, etc.** If the file has section headers, it hasn't been finalized by `/obsidian:standup` yet.

**The standup is incomplete if ANY of these are true:**
- File does not exist
- File contains section headers (`##`) — this means it's still a raw work-in-progress plan/log, not a finalized standup
- File content is clearly raw/unsynthesized (just dumped session data, no clean bullet summary)

**If the standup is incomplete**, do not silently proceed. Stop and tell the user:

> "Yesterday's standup (YYYY-MM-DD) hasn't been finalized — [reason: missing file / no Yesterday section / raw content]. Want me to run `/obsidian:standup` on that date first?"

If the user says yes, invoke `/obsidian:standup` via the Skill tool with the prior date, then continue with the briefing. If they decline, proceed without it — but note in the briefing's Yesterday section that it's reconstructed from incomplete data.

## Step 2 — Gather context (parallel)

Run these in parallel to collect all the data. Note: yesterday's standup was already read in Step 1 for the completeness gate — do NOT re-read or display it here. The user opens yesterday's notes themselves.

### A. Open follow-ups
```bash
source ~/.zprofile && obsidian read path="followups.md"
```
Filter to unchecked items (`- [ ]`). Flag any that are past their date as overdue.

### B. Active investigations
```bash
source ~/.zprofile && obsidian search query="Status: Active" path="investigations"
```
Read any active investigation files to get their summaries.

### C. PRs awaiting your review

**IMPORTANT:** `gh pr list` defaults to the current directory's repo, which may not be where PRs live. Use `gh api` with search queries to find PRs across all repos:

```bash
gh api "search/issues?q=review-requested:musicMan1337+is:open+is:pr&per_page=10" --jq '.items[] | {number, title, html_url, user: .user.login, repository: .repository_url}'
```

### D. Your open PRs (waiting on others)

Same issue — must search across all repos, not just the current directory:

```bash
gh api "search/issues?q=author:musicMan1337+is:open+is:pr&per_page=10" --jq '.items[] | {number, title, html_url, repository: .repository_url}'
```

Then for each PR, fetch review status:
```bash
gh api "repos/OWNER/REPO/pulls/NUMBER" --jq '{reviewDecision: .review_decision, headRefName: .head.ref}'
```

Or batch it by fetching from known repos:
```bash
gh pr list --author musicMan1337 --state open --repo OWNER/REPO --json number,title,url,headRefName,reviewDecision --limit 10
```

## Step 3 — Present the briefing

Show the user a structured summary. Do NOT include a Yesterday section — the user opens yesterday's notes themselves.

```
## Open Follow-ups
- [overdue items first, flagged]
- [upcoming items]
(or "None" if clear)

## Active Investigations
- [investigation name] — [status summary]
(or "None" if clear)

## PRs Awaiting Your Review
- [Repo #123](https://github.com/OWNER/REPO/pull/123) "Title" by @author
(or "None" if clear)

## Your Open PRs
- [Repo #456](https://github.com/OWNER/REPO/pull/456) "Title" — [branch] — [approved/changes requested/pending review]
(or "None" if clear)
```

**Every PR MUST be a clickable markdown link.** Format: `[Repo #NUMBER](https://github.com/OWNER/REPO/pull/NUMBER)`. Use the PR's `html_url` from the `gh api` response — never write a bare `#123` or plain repo-number. This applies to both the presented briefing AND the written standup file.

The **Open PRs** sections aren't necessarily TODO items — they're visibility bumps so PRs don't get forgotten. Include the branch name and review status so the user can quickly gauge which need attention.

## Step 4 — Draft today's plan

Based on everything above, draft a "Today" section with planned bullets. Use judgment:
- Overdue follow-ups become today items
- PRs awaiting your review become today items
- Active investigations carry forward
- Open PRs that need attention (changes requested, stale) carry forward
- Leave room — don't over-schedule, 3-6 bullets is ideal

Show the draft to the user and ask:
1. If they want to change any bullets
2. If they have **additions** — things not captured in Obsidian/GitHub (meetings, non-code tasks, things people mentioned in Slack/Teams)

Iterate until the user is happy.

## Step 5 — Write today's standup

Write today's standup file with today's plan plus the briefing context sections (follow-ups, investigations, PRs). Do NOT include a Yesterday section — yesterday's standup lives in its own file.

These sections stay in the file through the day for reference. End-of-day `/obsidian:standup` synthesis strips everything except the finalized Completed bullets.

```bash
source ~/.zprofile && obsidian create path="standup/$today.md" content="..." overwrite
```

**Format:**
```
## Today

[today's planned bullets from Step 3]

## Completed

<!-- standup-add appends here throughout the day -->

---
## Open Follow-ups

[follow-ups from Step 2 — or "None"]

## Active Investigations

[investigations from Step 2 — or "None"]

## PRs Awaiting Your Review

[PRs from Step 2 — each as `[Repo #NUMBER](html_url) "Title" by @author` — or "None"]

## Your Open PRs

[PRs from Step 2 — each as `[Repo #NUMBER](html_url) "Title" — branch — status` — or "None"]
```

**Every PR entry MUST be a clickable markdown link** using the PR's `html_url` from `gh api`. No bare `#123`.

The empty `## Completed` section is preemptive — `/obsidian:standup-add` appends to it throughout the day instead of creating it.

If today's standup file already exists, read it first and ask the user whether to overwrite or skip.

## Step 6 — Archive old standups

After writing today's standup, archive any files in `standup/` beyond the 10 most recent. Keep the 10 newest in `standup/` root; move the rest to `standup/archive/`.

```bash
source ~/.zprofile && obsidian files folder="standup"
```

Parse the output — filter to files directly under `standup/` (exclude `standup/archive/...`). Sort by filename descending (dates as `YYYY-MM-DD.md` sort naturally). Keep the first 10; move the rest.

For each file to archive:
```bash
source ~/.zprofile && obsidian move path="standup/YYYY-MM-DD.md" to="standup/archive/YYYY-MM-DD.md"
```

If the archive move fails with `ENOENT: no such file or directory` on the destination, the `standup/archive/` folder doesn't exist yet — create it once with a plain `mkdir -p <vault>/standup/archive` (the vault path is visible in the ENOENT error). Then retry the moves.

Skip archiving if there are 10 or fewer files in `standup/` root.

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Dates come from Step 0, not memory.** Never infer today's weekday from context — always run the Step 0 date script first. The script already handles the Monday→Friday rollback.
- **Don't fabricate plans.** Only draft today items from real signals (follow-ups, PRs, investigations, carry-over). If there's nothing, say so — the user will add their own.
- **No Yesterday section.** Don't display or write a Yesterday section — yesterday's standup lives in its own file; the user opens it directly. Step 1 reads it only for the completeness gate.
- **The user's additions are the most important part.** The automated stuff is just a starting point. Always ask for additions before writing.
- **gh CLI failures:** If GitHub is unreachable, skip the PR sections and note it. Don't block the whole briefing.
- **Open PRs are visibility, not action items.** Don't auto-promote every open PR to a TODO. Only PRs that need attention (review requested, changes requested, stale) should become Today items.
