---
name: obsidian:briefing
model: haiku
description: Morning briefing — restore context, list follow-ups, draft standup plan. Triggers on: briefing, start my day, where did I leave off
---

# Daily Briefing

Generate a morning context-restore by pulling from Obsidian notes, GitHub, and Claude session history. Then draft today's standup entry.

## Input

**Request:** $ARGUMENTS

No args needed — defaults to "brief me for today". The user might also say:
- "briefing for monday" (if catching up after a weekend)
- "what did I miss yesterday"

## Step 0 — Gather (MANDATORY, first action)

Do not guess dates or read vault files one at a time. Run the gather script first, it returns authoritative dates plus all the local-vault context in one call (reads the vault directly):

```bash
node ~/.claude/commands/obsidian/_lib/gather.mjs --for briefing
```

The bundle contains:
- `today`, `yesterday`, `weekdayToday` — authoritative; use these everywhere, never substitute a guessed date
- `yesterdayStandup` — `{exists, content, isFinalized}` for the prior workday's standup (Step 1 gate)
- `todayStandup` — `{exists, content}` (Step 5 existence check)
- `followups` — `{content, unchecked}` (Step 2A)
- `activeInvestigations` — `[{slug, content}]` already filtered to `Status: Active` (Step 2B)
- `standupFiles` — all standup slugs for the Step 6 archive check

## Step 1 — Check prior day's standup (BLOCKING)

This step gates the entire briefing. Do NOT proceed to Step 2 until resolved. Use `yesterdayStandup` from the gather bundle, no extra read.

**A completed standup is just a title and bullet points — no sections like `## Today`, `## Completed`, `## Yesterday`, etc.** `yesterdayStandup.isFinalized` is already computed.

**The standup is incomplete if ANY of these are true:**
- `yesterdayStandup.exists` is `false`
- `yesterdayStandup.isFinalized` is `false` (still has `##` section headers, a raw work-in-progress plan/log)
- Content is clearly raw/unsynthesized (just dumped session data, no clean bullet summary)

**If the standup is incomplete**, do not silently proceed. Stop and tell the user:

> "Yesterday's standup (YYYY-MM-DD) hasn't been finalized — [reason: missing file / no Yesterday section / raw content]. Want me to run `/obsidian:standup` on that date first?"

If the user says yes, invoke `/obsidian:standup` via the Skill tool with the prior date, then continue with the briefing. If they decline, proceed without it — but note in the briefing's Yesterday section that it's reconstructed from incomplete data.

## Step 2 — Gather context (parallel)

Run these in parallel to collect all the data. Note: yesterday's standup was already read in Step 1 for the completeness gate — do NOT re-read or display it here. The user opens yesterday's notes themselves.

### A. Open follow-ups
Use `followups.unchecked` from the gather bundle (already filtered to `- [ ]`). Flag any past their date as overdue.

### B. Active investigations
Use `activeInvestigations` from the gather bundle (already filtered to `Status: Active`, with each note's content for summaries).

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

### E. Outstanding Dependabot PRs (Viper) — these ARE TODO items

Unlike the open-PR sections above (visibility only), Dependabot PRs Derek hasn't handled are real action items — they go in today's plan. List open Dependabot PRs on `tagemployerservices/Viper` that Derek hasn't already commented on or reviewed:

```bash
gh pr list --repo tagemployerservices/Viper --author "app/dependabot" --state open \
    --json number,title,url,createdAt
```

For each, exclude any Derek already handled (commented OR reviewed):
```bash
gh pr view <num> --repo tagemployerservices/Viper --json reviews,comments \
    --jq '[.reviews[].author.login, .comments[].author.login] | map(select(. == "musicMan1337")) | length'
```
Non-zero → handled, drop it. Zero → unhandled, keep it. Do NOT run `/dev:viper-dependabot` or audit/build anything here — just list the queue so it becomes a today item.

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

## Dependabot PRs (Viper) — action items
- [Viper #789](https://github.com/tagemployerservices/Viper/pull/789) "bump axios 1.6.2 → 1.7.4" — opened Nd ago
(or "None" if clear)
```

**Every PR MUST be a clickable markdown link.** Format: `[Repo #NUMBER](https://github.com/OWNER/REPO/pull/NUMBER)`. Use the PR's `html_url` from the `gh api` response — never write a bare `#123` or plain repo-number. This applies to both the presented briefing AND the written standup file.

**Case system numbers MUST be clickable too.** Any Viper `caseid` in a Today bullet (or anywhere in the file) links as `[353105](https://my.ebacon.com/index.php/viper/#caseSystem/353105)` (link the number), or in a header `**Case [353105](https://my.ebacon.com/index.php/viper/#caseSystem/353105) - description**`. Every case ID resolves to this URL by construction, so always link it. Same rule for artifacts/dashboards/other URLs: wrap in a markdown link when you have the URL, never paste it bare. Never fabricate a URL.

The **Open PRs** sections aren't necessarily TODO items — they're visibility bumps so PRs don't get forgotten. Include the branch name and review status so the user can quickly gauge which need attention.

## Step 4 — Draft today's plan

Based on everything above, draft a "Today" section with planned bullets. Use judgment:
- Overdue follow-ups become today items
- PRs awaiting your review become today items
- **Outstanding Dependabot PRs (Step 2E) become today items** — e.g. "Review N Viper Dependabot PRs (`/dev:viper-dependabot`)". Roll the queue into one bullet rather than one per PR unless the user wants them itemized.
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
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs write "standup/$today.md" <<'EOF'
...
EOF
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

## Dependabot PRs (Viper)

[unhandled Dependabot PRs from Step 2E — each as `[Viper #NUMBER](html_url) "Title" — opened Nd ago` — or "None". These are action items, also reflected in the Today plan.]
```

**Every PR entry MUST be a clickable markdown link** using the PR's `html_url` from `gh api`. No bare `#123`.

The empty `## Completed` section is preemptive — `/obsidian:standup-add` appends to it throughout the day instead of creating it.

If `todayStandup.exists` (from the gather bundle) is `true`, ask the user whether to overwrite or skip before writing.

## Step 6 — Archive old standups

After writing today's standup, archive any files in `standup/` beyond the 10 most recent. Keep the 10 newest in `standup/` root; move the rest to `standup/archive/`.

Use `standupFiles` from the gather bundle (the slugs directly under `standup/`, already excluding `standup/archive/...`). Sort descending (dates as `YYYY-MM-DD` sort naturally). Keep the first 10; move the rest.

For each file to archive:
```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs move "standup/YYYY-MM-DD.md" "standup/archive/YYYY-MM-DD.md"
```

If the archive move fails with `ENOENT: no such file or directory` on the destination, the `standup/archive/` folder doesn't exist yet — create it once with a plain `mkdir -p <vault>/standup/archive` (the vault path is visible in the ENOENT error). Then retry the moves.

Skip archiving if there are 10 or fewer files in `standup/` root.

## Gotchas

- **There is no `obsidian` CLI. Never call it.** The `obsidian` on PATH is the app binary (`/Applications/Obsidian.app/Contents/MacOS/obsidian`). It has no `create`/`read`/`append`/`search` subcommands: passing it `create path=... content=...` silently launches the app and leaves a stray `Untitled N.md` in the vault root, writing nothing. Vault access goes through `_lib/vault-cli.mjs` (or `_lib/gather.mjs` for the bundled reads).
- **Dates come from Step 0, not memory.** Never infer today's weekday from context — always run the Step 0 date script first. The script already handles the Monday→Friday rollback.
- **Don't fabricate plans.** Only draft today items from real signals (follow-ups, PRs, investigations, carry-over). If there's nothing, say so — the user will add their own.
- **No Yesterday section.** Don't display or write a Yesterday section — yesterday's standup lives in its own file; the user opens it directly. Step 1 reads it only for the completeness gate.
- **The user's additions are the most important part.** The automated stuff is just a starting point. Always ask for additions before writing.
- **gh CLI failures:** If GitHub is unreachable, skip the PR sections and note it. Don't block the whole briefing.
- **Open PRs are visibility, not action items.** Don't auto-promote every open PR to a TODO. Only PRs that need attention (review requested, changes requested, stale) should become Today items.
- **Dependabot PRs ARE action items.** Unlike your own open PRs, unhandled Viper Dependabot PRs (Step 2E) always become a today bullet. But the briefing only *lists* them — it never runs `/dev:viper-dependabot`; that's Derek's call during the day.
