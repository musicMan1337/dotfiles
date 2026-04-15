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

## Step 0 — Check prior day's standup (BLOCKING)

This step gates the entire briefing. Do NOT proceed to Step 1 until resolved.

Read the prior workday's standup file:

```bash
source ~/.zprofile && obsidian read path="standup/YYYY-MM-DD.md"
```
(Use previous workday's date — Friday if today is Monday.)

**A completed standup is just a title and bullet points — no sections like `## Today`, `## Completed`, `## Yesterday`, etc.** If the file has section headers, it hasn't been finalized by `/obsidian:standup` yet.

**The standup is incomplete if ANY of these are true:**
- File does not exist
- File contains section headers (`##`) — this means it's still a raw work-in-progress plan/log, not a finalized standup
- File content is clearly raw/unsynthesized (just dumped session data, no clean bullet summary)

**If the standup is incomplete**, do not silently proceed. Stop and tell the user:

> "Yesterday's standup (YYYY-MM-DD) hasn't been finalized — [reason: missing file / no Yesterday section / raw content]. Want me to run `/obsidian:standup` on that date first?"

If the user says yes, invoke `/obsidian:standup` via the Skill tool with the prior date, then continue with the briefing. If they decline, proceed without it — but note in the briefing's Yesterday section that it's reconstructed from incomplete data.

## Step 1 — Gather context (parallel)

Run these in parallel to collect all the data:

### A. Yesterday's standup (what was done)
```bash
source ~/.zprofile && obsidian read path="standup/YYYY-MM-DD.md"
```
Use yesterday's date (or last workday if today is Monday).

### B. Open follow-ups
```bash
source ~/.zprofile && obsidian read path="followups.md"
```
Filter to unchecked items (`- [ ]`). Flag any that are past their date as overdue.

### C. Active investigations
```bash
source ~/.zprofile && obsidian search query="Status: Active" path="investigations"
```
Read any active investigation files to get their summaries.

### D. PRs awaiting your review

**IMPORTANT:** `gh pr list` defaults to the current directory's repo, which may not be where PRs live. Use `gh api` with search queries to find PRs across all repos:

```bash
gh api "search/issues?q=review-requested:musicMan1337+is:open+is:pr&per_page=10" --jq '.items[] | {number, title, html_url, user: .user.login, repository: .repository_url}'
```

### E. Your open PRs (waiting on others)

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

## Step 2 — Present the briefing

Show the user a structured summary:

```
## Yesterday
[condensed version of yesterday's standup — pithy one-liners per section, not the full verbose standup]

## Open Follow-ups
- [overdue items first, flagged]
- [upcoming items]
(or "None" if clear)

## Active Investigations
- [investigation name] — [status summary]
(or "None" if clear)

## PRs Awaiting Your Review
- #123 "Title" by @author — [repo]
(or "None" if clear)

## Your Open PRs
- #456 "Title" — [branch] — [approved/changes requested/pending review]
(or "None" if clear)
```

The **Open PRs** sections aren't necessarily TODO items — they're visibility bumps so PRs don't get forgotten. Include the branch name and review status so the user can quickly gauge which need attention.

## Step 3 — Draft today's plan

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

## Step 4 — Write today's standup

Write today's standup file combining yesterday's work and today's plan:

```bash
source ~/.zprofile && obsidian create path="standup/YYYY-MM-DD.md" content="..." overwrite
```

**Format:**
```
## Yesterday

[yesterday's bullets — copied from yesterday's standup file]

---
## Today

[today's planned bullets from Step 3]
```

If today's standup file already exists, read it first and ask the user whether to overwrite or skip.

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Monday morning:** Yesterday means Friday. Skip weekends unless the user explicitly asks about them.
- **Don't fabricate plans.** Only draft today items from real signals (follow-ups, PRs, investigations, carry-over). If there's nothing, say so — the user will add their own.
- **Yesterday's standup is the source of truth for "Yesterday".** Don't re-synthesize from session data if the file already exists — it was already reviewed and approved.
- **Condense Yesterday, don't copy.** The standup file is intentionally verbose and detailed. For the briefing, condense each numbered section into a single pithy line — just enough to jog memory, not re-read the full record. Example: standup says "Updated Trust/FringeSaver/TimeSaver quote templates with new rollover fringe/non-fringe adjustment bullets per Case #339646 requirements, created eBaconQuote CLAUDE.md scope doc for cross-repo context" → briefing says "Case #339646 — eBacon quote template updates".
- **The user's additions are the most important part.** The automated stuff is just a starting point. Always ask for additions before writing.
- **gh CLI failures:** If GitHub is unreachable, skip the PR sections and note it. Don't block the whole briefing.
- **Open PRs are visibility, not action items.** Don't auto-promote every open PR to a TODO. Only PRs that need attention (review requested, changes requested, stale) should become Today items.
