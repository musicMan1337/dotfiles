---
name: dev:viper-worktree
description: Personal wrapper around Viper's `viper-dev-worktree` skill. Two modes. Mode A (default, run from anywhere): Phase 1 picks/creates a worktree and kicks Docker into the background, Phase 2 looks up the case in SQL Server and writes `PLAN_<slug>.md` into the worktree root, then prints a `cd` command. Mode B (run with no args from inside a worktree): reads the worktree's `PLAN_*.md`, confirms with the user, and starts implementing. Triggers on: viper worktree picker, list viper worktrees, pick a worktree, start a viper worktree, switch viper worktrees, my worktree wrapper, viper plan from case, /dev:viper-worktree.
model: opus
---

# /dev:viper-worktree

Personal wrapper around Viper's source-controlled `viper-dev-worktree` skill. Lives in `~/.claude/commands/dev/`; safe to customize without touching the Viper repo.

## Mode detection (do this first)

Check `pwd` and args before anything else.

- **Mode B (implementation):** `pwd` is under `/Users/derek/eBacon/Viper/.worktrees/<slug>/` AND no args were passed. Jump to the "Mode B" section at the bottom.
- **Mode A (default):** anything else. Continue with the Phase 1 / Phase 2 flow below.

## What Mode A does (vs the upstream skill)

The upstream skill at `/Users/derek/eBacon/Viper/.claude/skills/viper-dev-worktree/SKILL.md` is the source of truth for *how* worktrees + Docker stacks work. This wrapper adds:

1. A scan of existing worktrees + Docker container state.
2. An interactive picker (existing or new branch).
3. A nuanced Docker question that enforces "one stack running at a time."
4. A "build the image but leave it stopped" path, so the image is warm but RAM is free.
5. **Phase 2:** SQL Server case lookup and `PLAN_<slug>.md` write into the worktree root.
6. A final `cd <abs-path>` line you can paste into a fresh terminal.

## Load these into context before doing anything (Mode A)

Read these files first. They are operational truth; do not paraphrase or duplicate their gotchas here.

1. `/Users/derek/eBacon/Viper/.claude/skills/viper-dev-worktree/SKILL.md`
2. `/Users/derek/eBacon/Viper/DEV-WORKTREE-DOCKER.md` (if it exists)
3. `/Users/derek/eBacon/Viper/bin/viper-new-worktree.sh` (skim, you'll invoke it)
4. `/Users/derek/eBacon/Viper/bin/viper-docker.sh` (skim, for provision/teardown semantics)

If the user invokes this skill outside the Viper repo, paths are still absolute. You can run from anywhere.

## Constants

- **Viper repo:** `/Users/derek/eBacon/Viper`
- **Worktree root:** `/Users/derek/eBacon/Viper/.worktrees/`
- **Container naming:** `viper-worktree-<slug>-<service>-1` (services: `app`, `hotreload`, `sandbox`, `ci4`, ...)
- **Compose project:** `viper-worktree-<slug>`
- **"Stack running" signal:** an `-app-1` container in `running` state. Ignore hotreload-only or sandbox-only states for this check.
- **PLAN file:** `<worktree-root>/PLAN_<slug>.md`. Worktree-ephemeral, relies on existing global/repo gitignore.

---

# Mode A: Phase 1 (worktree + Docker kickoff)

### Step 1: Scan state (parallel)

```bash
ls -1t /Users/derek/eBacon/Viper/.worktrees/ 2>/dev/null
docker ps -a --filter "name=viper-worktree-" --filter "name=-app-1" --format '{{.Names}}\t{{.State}}'
```

From the docker list:

- Extract slug per row: strip `viper-worktree-` prefix and `-app-1` suffix.
- Bucket each slug as `running`, `stopped` (state `exited` or `created`), or absent (no `-app-1` container = image never built).
- If **>1 slug is running**, surface that to the user before continuing. Two Viper stacks running concurrently will OOM most Macs. Offer to stop the extras first.

Cross-reference: each entry in `ls .worktrees/` is a candidate; annotate it with its container state.

### Step 2: Pick a worktree (Q1)

Use `AskUserQuestion`. Build options like this:

- One option per existing worktree, labelled `<slug>  [<state>]` where state is `running`, `stopped`, or `no-image`. Use `ls -1t` order so most-recently-touched comes first.
- One option `Create new worktree`.

If there are 4+ existing worktrees, show the top 3 + `Create new`, and mention in the question text: "N more not shown; pick Other and type the slug." The `AskUserQuestion` "Other" path is your escape hatch for slug typing.

If the user picks `Create new` (or types a non-existent slug as Other), follow up with a free-text prompt for the branch name. Follow Viper's branch convention `<Name>/<CaseId>-<description>` per the loaded upstream skill. Don't invent a CaseId; ask if absent.

### Step 3: Decide on Docker (Q2)

Use `AskUserQuestion`. Phrasing depends on current state:

- **A different worktree is currently running:** include that fact in the question text, e.g. "`alex-343249` is currently running; starting another stack will stop it first."
- **Nothing running:** no preamble needed.

Options (up to 4):

1. **Start Docker now.** If another stack is running, stop it first.
2. **Build only, leave stopped.** Image gets built so a future `docker compose up -d` is fast, but RAM is freed once the build finishes.
3. **Skip Docker entirely.** Only show this option for an *existing* worktree that already has a built image (`state == stopped`). For a new worktree, always build at minimum (per user preference: warm image, cold RAM).
4. *(omit if not applicable)*

### Step 4: Kick off Docker in background, then continue

**Existing worktree:**

- **Start Docker now:**
  - If a different worktree is running: `cd /Users/derek/eBacon/Viper/.worktrees/<other-slug> && docker compose down` (NO `-v`, preserves sessions).
  - Then: `cd /Users/derek/eBacon/Viper/.worktrees/<picked-slug> && docker compose up -d` (`run_in_background: true`).
- **Build only, leave stopped:**
  - If image exists (state was `stopped`): no-op, image is already built.
  - If no image (state was `no-image`): `cd <worktree> && docker compose build && docker compose down` (`run_in_background: true`).
- **Skip Docker:** nothing to do.

**New worktree:**

- Run `./bin/viper-new-worktree.sh <branch-name>` from `/Users/derek/eBacon/Viper`. This branches from `master` (override only if the user explicitly says so; see upstream skill `--from` rules), creates `.worktrees/<slug>/`, provisions ports, and runs `docker compose up -d --build`.
- If "Start Docker now" was chosen and a different stack is running, stop it first (`cd <other>/.worktrees/<other-slug> && docker compose down`) **before** launching the new-worktree script.
- If "Build only" was chosen: chain `; cd .worktrees/<new-slug> && docker compose down` after the script so the image is warm but RAM is free once the build finishes.
- **Always run the new-worktree script in the background** (`run_in_background: true`). The user does not want to wait. The worktree directory is created early in the script, so Phase 2 work below can proceed against the worktree root within a few seconds.

After kickoff, **immediately move to Phase 2.** Do not wait for the Docker build to finish.

---

# Mode A: Phase 2 (case lookup + PLAN file)

### Step 5: Resolve the case ID (or fall back to free-text context)

Parse the case ID from the branch name. Viper convention: `<Name>/<CaseId>-<description>` (e.g. `Derek/339224-CI4` → case `339224`). For existing worktrees, derive the branch from the worktree's git config or infer from the slug (slug is lowercased, slashes replaced with `-`; `derek-339224-ci4` maps back to `Derek/339224-CI4`).

If the case ID is not parseable, decide based on whether the user gave you context:

- **No case ID, but user provided free-text context** when creating the worktree (args to the skill, a description typed during the new-branch prompt, or anything they volunteered about the work): proceed to Step 7 and write a **minimal context-only PLAN** (no SQL lookup). Skip Step 6.
- **No case ID and no user context:** skip Phase 2 entirely and jump to Step 8. Do not write a PLAN file. Do not prompt the user for context; if they wanted a plan they would have said so.

### Step 6: Query SQL Server for case meta

Use the `mcp__sqlsrv__query` tool. Pull the relevant fields from the `cases` table:

```sql
SELECT CaseId, Client, AssignedTo, Creator, CaseTitle, CaseDescription,
       CaseType, DevStatus, DueDate, CompleteDate
FROM cases
WHERE CaseId = <id>
```

- If 0 rows returned, ask the user once to confirm the case ID (could be a typo). If they confirm it's correct and the case genuinely doesn't exist in this DB, skip Phase 2 and jump to Step 8.
- If multiple rows (shouldn't happen since `CaseId` is the key, but defensively): ask the user which.

### Step 7: Write `PLAN_<slug>.md`

Write the file to `<worktree-root>/PLAN_<slug>.md`. Two shapes, depending on what Step 5 resolved:

**Shape A: Case meta** (Step 6 returned a row). Dump the SQL fields; user fills in the plan body later.

```markdown
# PLAN: <slug>

**Branch:** `<branch-name>`
**Case:** [<CaseId>] <CaseTitle>
**Client:** <Client>
**Type:** <CaseType>
**Dev Status:** <DevStatus>
**Assigned:** <AssignedTo>  |  **Creator:** <Creator>
**Due:** <DueDate>  |  **Completed:** <CompleteDate or "—">

---

## Case Description

<CaseDescription verbatim from SQL>

---

## Notes / Plan

<!-- user fills in -->
```

**Shape B: Free-text context only** (no case ID, but the user volunteered direction in args or during the new-branch prompt). Capture the user's words verbatim; do not embellish.

```markdown
# PLAN: <slug>

**Branch:** `<branch-name>`
**Case:** n/a

---

## Context

<user's free-text direction, verbatim>

---

## Notes / Plan

<!-- user fills in -->
```

Use `,` `;` `:` `(` `)` `.` instead of em-dashes anywhere in the rendered output. If `CompleteDate` is null, write `n/a` rather than the em-dash character.

**Clarifying questions:** ask the user only if something is genuinely ambiguous (case ID couldn't be resolved, branch name doesn't follow convention, SQL returned unexpected shape). Otherwise write the file and move on. Do not pepper the user.

If the worktree directory does not yet exist (new-worktree script still bootstrapping), poll briefly (up to ~10s) before writing. The script creates the directory early.

### Step 8: Print the `cd` command

Always end the turn with the cd line in its own fenced code block, on its own line, so it's one-click copy. Example:

```
cd /Users/derek/eBacon/Viper/.worktrees/derek-339224-ci4
```

No other text after that block. The user wants to grab it and paste into a fresh terminal.

If the new-worktree script is still running in the background, note above the cd block that the Docker build is still running and the user can paste the cd as soon as the worktree dir lands (usually a few seconds). One short sentence, not a paragraph.

If a PLAN file was written, mention its filename in that same one-liner so the user knows it's there.

---

# Mode B: Implementation (already in a worktree, no args)

User has cd'd into the worktree and is ready to start coding from the plan.

### Step B1: Locate the PLAN file

```bash
ls PLAN_*.md 2>/dev/null
```

- If exactly one match, that's the plan file.
- If zero matches, tell the user there's no `PLAN_*.md` in this worktree and offer to (1) re-run Mode A to generate one or (2) proceed without a plan. Numbered options.
- If multiple matches (unexpected), ask which to use.

### Step B2: Summarize the plan

Read the plan file. Print a terse summary to the user:

- Case ID + title
- Dev status
- Whatever the user wrote under `## Notes / Plan` (verbatim, that's the actual scope)

Keep it short. The user wrote it; they know what's in it.

### Step B3: Confirm and start

Ask the user (numbered options, per global rule):

1. Start coding
2. Refine the plan first
3. Stop

On "Start coding", begin executing the plan tasks directly. Use TaskCreate to track milestones if the work has multiple discrete steps. Otherwise just start.

On "Refine the plan first", open the PLAN file in edit mode, ask what to change, write the changes, then re-confirm.

---

## Gotchas

- **One stack at a time.** Docker's memory ceiling means two Viper stacks running simultaneously will OOM the user's machine. Always stop the running one before starting another. Never bring up a second stack without surfacing the swap to the user first.
- **Slug vs branch.** `viper-new-worktree.sh` takes the **branch name** (e.g. `Derek/339224-CI4`), not the slug (`derek-339224-ci4`). The slug is auto-derived. Worktrees are listed by slug.
- **"Build only" is a post-action, not a flag.** `viper-new-worktree.sh` always does `docker compose up -d --build`. There is no `--no-up` flag. To leave a stack stopped, let the script finish then run `docker compose down`.
- **`docker compose down` without `-v`.** `-v` deletes the `viper-sessions` named volume, which wipes login state. Never use `-v` in this skill's flow.
- **`-app-1` is the canonical "running" signal.** Some worktrees only ship hotreload + sandbox; some have `ci4` containers. Check `app` to decide whether the stack is up. Don't trip on hotreload-only or sandbox-only states.
- **`AskUserQuestion` caps at 4 options.** Use the "Other" text-input escape for the 4+-worktrees case. Don't try to fit 5 worktrees into 4 buttons.
- **`viper-new-worktree.sh` defaults to branching from `master`.** Do not silently use a different ref. If the user says "from my current branch" or similar, pass `--from <ref> <branch>` explicitly and confirm before creating, per the upstream skill.
- **This skill never tears down.** If the user asks to remove a worktree, defer to the upstream `viper-dev-worktree` teardown flow. Teardown is destructive and has its own confirmation gates.
- **Leftover containers from removed worktrees.** If `docker ps -a` shows a `viper-worktree-<slug>-app-1` whose `.worktrees/<slug>/` directory no longer exists, mention it but don't auto-clean. The user may want to keep the image cached.
- **Phase 2 does not block Phase 1.** Docker kickoff is in the background. Run SQL + write PLAN concurrently. Print cd last.
- **No case ID, no context = skip Phase 2.** Don't try to invent a case or prompt the user for direction. If they volunteered free-text context when creating the worktree, write a minimal context-only PLAN (Shape B) instead. Silence means skip.
- **PLAN file is ephemeral.** It lives only in the worktree. Rely on existing global/repo gitignore patterns; do not modify `.gitignore` or `.git/info/exclude` from this skill.
- **Mode B trigger is strict.** Only switch to Mode B when `pwd` is under `.worktrees/<slug>/` AND no args were passed. Any args mean the user wants Mode A behavior.
- **Customize this file freely.** It's your personal wrapper; you own it. The upstream Viper skill is the canonical thing and stays untouched.
