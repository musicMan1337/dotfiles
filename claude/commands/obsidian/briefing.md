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

## Step 0 — Check prior day's standup

Before gathering today's context, check if the prior workday's standup has been cleaned up:

```bash
source ~/.zprofile && obsidian read path="standup/YYYY-MM-DD.md"
```
(Use previous workday's date — Friday if today is Monday.)

**If no standup file exists for the prior workday**, or if it looks like raw/unsynthesized content, offer to run the `/obsidian:standup` skill on that date first. Ask the user: "Yesterday's standup hasn't been written up. Want me to generate it first?"

If the user says yes, invoke `/obsidian:standup` via the Skill tool with the prior date, then continue with the briefing. If they decline, proceed without it.

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
```bash
gh pr list --search "is:open review-requested:musicMan1337" --json number,title,url,author,repository --limit 10
```

### E. Your open PRs (waiting on others)
```bash
gh pr list --author musicMan1337 --state open --json number,title,url,reviews,headRefName --limit 10
```

## Step 2 — Present the briefing

Show the user a structured summary:

```
## Yesterday
[yesterday's standup bullets — read from standup file]

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
- **The user's additions are the most important part.** The automated stuff is just a starting point. Always ask for additions before writing.
- **gh CLI failures:** If GitHub is unreachable, skip the PR sections and note it. Don't block the whole briefing.
- **Open PRs are visibility, not action items.** Don't auto-promote every open PR to a TODO. Only PRs that need attention (review requested, changes requested, stale) should become Today items.
