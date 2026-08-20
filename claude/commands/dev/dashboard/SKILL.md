---
name: dev:dashboard
model: sonnet
description: Refresh the case-queue dashboard from the Viper case system and set today's focus. Reads the live queue, updates the artifact, and rewrites its Today section. Triggers on, dashboard, case dashboard, refresh the dashboard, what should I work on today, my queue, case queue, what's on my plate, update the case dashboard, set today's focus, /dev:dashboard.
---

# Case Queue Dashboard

Two jobs on one artifact: keep it true to the live queue, and decide what today's focus is. `obsidian:briefing` reads the Today section you write, so the focus set becomes the standup plan.

## The artifact

`~/dotfiles/artifacts/case-queue-in-discussion.html`

Local-only until published; `artifacts/` is gitignored. The page is in Artifact-content form (opens with `<title>`, then `<style>`; no doctype, `<html>`, `<head>`, or `<body>` tags of its own) and inlines `mammoth.css`. Keep both properties on every edit, or publishing breaks.

Sections, in page order: headline stats, the four project cards, overdue, dated timeline, the CI4 due-curve chart, the DevStatus finding, **Today**, query caveats.

The Today section is wrapped in `<!-- today:start -->` / `<!-- today:end -->`. Those markers are the contract with `obsidian:briefing`. Moving or renaming them silently empties the briefing's dashboard input.

## Refresh

Run the queries in `queries.sql` (same directory) through the viper-stage MCP. Load the `viper-stage-plugin:viper-stage` skill first; that is the house rule for any Viper Stage read.

`queries.sql` is the single source of truth for how every number on the page is computed. When you need a cut it does not cover, add it there rather than writing a one-off, so the next run reproduces the same figures.

Then reconcile the page against what came back. What matters per section:

- **Stats and buckets.** Numbers only. Update in place.
- **Overdue.** Every one, with an age pill. A case that left the list is the most useful thing you can report.
- **Timeline.** Eight-week horizon. Drop dates that passed, pull in dates that entered the window.
- **Project cards.** Child counts and the horizon line.
- **CI4 chart.** Recompute bar heights as a percentage of the tallest month, and move the `spike` class to whichever month is tallest.
- **DevStatus finding.** The page is named after this: 225 of 229 cases read `In Discussion`. If that ratio changes materially, the finding's copy and its proportion bar both need rewriting.
- **Masthead date and the Today stamp.** Both carry the run date.

Prose that is still accurate stays as written. Rewrite a section's copy when the underlying fact moved, not because you regenerated the file.

## Today

Pick 3 to 5 items and write them into the Today section, ordered by what unblocks the most downstream work rather than by due date. That ordering is the whole value of the section; a due-date sort is something the case system already gives him.

What earns a slot:

- A dated item inside a week, especially one whose successors wait on it
- Anything overdue, with age as the tiebreak
- An action that moves work off the queue entirely (reassignment, a split, a close-out)
- Something already in flight yesterday that has an open loop, so it does not stall

What does not: a whole project as one bullet, a bulk backlog that wants a scheduled sweep instead of a daily slot, or a fifth item that exists to round out the list.

Each item is a title plus one sentence saying why it is today's work, naming the case, PR, or date that makes it urgent. `today.mjs` extracts exactly the `<h3>` and the first `<p>` of each `<li>`, so keep that shape.

Reactive work (PR reviews, inbound error cases) belongs in one capped item at the bottom, not spread across several.

## Verify

After editing, confirm the page still parses and the contract holds:

```bash
node ~/.claude/commands/dev/dashboard/today.mjs
grep -ciE '<!doctype|<html|<body' ~/dotfiles/artifacts/case-queue-in-discussion.html   # expect 0
python3 -c "print(open('$HOME/dotfiles/artifacts/case-queue-in-discussion.html').read().count(chr(8212)))"  # expect 0
```

`today.mjs` printing today's stamp and your items is the proof that briefing will see them. If it prints a `(no dashboard Today section: ...)` line, the markers broke.

## Report

Print the file path and what changed: counts that moved, cases that closed, cases that entered or left overdue, and the focus set. Nothing else. Do not open a browser.

## Publishing

The page is a private artifact, not a local file, once published; publishing is his call, so offer it as a numbered option and wait. On a redeploy pass the existing artifact URL so it updates in place instead of claiming a new one, and keep the title and favicon stable across runs. Register or update the row in the Obsidian artifacts manifest on any publish, per `augment:artifact-design`.

## Gotchas

- **The MCP times out on this table under load.** `validate_query` kept answering while `query_database` timed out on a `COUNT(*)` against 229 rows on 2026-08-20. Retry once, then say the numbers are stale rather than reporting the last known figures as current.
- **`DevStatus` cannot tell you what is in flight.** Nearly the whole queue reads `In Discussion`, including finished-but-unclosed work. Recency of `DateCreated`, an open PR, or yesterday's standup are better signals for what is actually moving.
- **`CaseProject` is populated for one project only** (Vuln OSV). Find project parents with `DevStatus = 'Project'`; grouping by `CaseProject` reports three of the four projects as having no children.
- **`FolderId` is 0 or null across his whole queue,** so folders carry no grouping. Title prefixes do, which is why the bucket query pattern-matches titles.
- **`t_folder`'s column is `Name`, not `FolderName`.** The obvious guess errors.
- **Counts are `AssignedTo` only.** Cases he created and handed off are invisible here. Say so when reporting a total, since it reads as his whole workload otherwise.
- **This is the stage database.** Fine for planning, and worth naming in the caveat line so no one treats a figure as production truth.
- **Regenerating the whole file loses hand edits.** Edit the sections that moved. He tunes copy on this page between runs.
- **The title is a finding, not a label.** "In Discussion" only makes sense while the status field is empty of meaning. If that gets fixed, the page needs a new name, which is a deliberate identity change to raise with him, not a silent rename.
