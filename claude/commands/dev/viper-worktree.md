---
name: dev:viper-worktree
description: Personal wrapper around Viper's `viper-dev-worktree` skill. Scans existing Viper worktrees + Docker container state, presents an interactive picker (pick existing or create new branch), handles Docker start/build-and-stop logic with single-stack enforcement, then prints a copy-pasteable `cd` command. Triggers on: viper worktree picker, list viper worktrees, pick a worktree, start a viper worktree, switch viper worktrees, my worktree wrapper, /dev:viper-worktree.
model: opus
---

# /dev:viper-worktree

Personal wrapper around Viper's source-controlled `viper-dev-worktree` skill. Lives in `~/.claude/commands/dev/`; safe to customize without touching the Viper repo.

## What this does (vs the upstream skill)

The upstream skill at `/Users/derek/eBacon/Viper/.claude/skills/viper-dev-worktree/SKILL.md` is the source of truth for *how* worktrees + Docker stacks work. This wrapper adds:

1. A scan of existing worktrees + Docker container state.
2. An interactive picker (existing or new branch).
3. A nuanced Docker question that enforces "one stack running at a time."
4. A "build the image but leave it stopped" path, so the image is warm but RAM is free.
5. A final `cd <abs-path>` line you can paste into a fresh terminal.

## Load these into context before doing anything

Read these files first. They are the operational truth; do not paraphrase or duplicate their gotchas here.

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

## Flow

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

### Step 4: Execute

**Existing worktree:**

- **Start Docker now:**
  - If a different worktree is running: `cd /Users/derek/eBacon/Viper/.worktrees/<other-slug> && docker compose down` (NO `-v`, preserves sessions).
  - Then: `cd /Users/derek/eBacon/Viper/.worktrees/<picked-slug> && docker compose up -d`.
- **Build only, leave stopped:**
  - If image exists (state was `stopped`): no-op, image is already built.
  - If no image (state was `no-image`): `cd <worktree> && docker compose build` then ensure it's down.
- **Skip Docker:** nothing to do.

**New worktree:**

- Run `./bin/viper-new-worktree.sh <branch-name>` from `/Users/derek/eBacon/Viper`. This branches from `master` (override only if the user explicitly says so; see upstream skill `--from` rules), creates `.worktrees/<slug>/`, provisions ports, and runs `docker compose up -d --build`.
- If "Start Docker now" was chosen and a different stack is running, stop it first (`cd <other>/.worktrees/<other-slug> && docker compose down`) **before** launching the new-worktree script.
- If "Build only" was chosen: let the script finish (it always does build + up), then `cd .worktrees/<new-slug> && docker compose down` to free RAM while keeping the image.
- **Run the script in the background** (`run_in_background: true` on the Bash call). The user explicitly does not want to wait for the Docker build to finish. The worktree directory is created early in the script, so the `cd` command you print in Step 5 will resolve within a few seconds.

### Step 5: Print the `cd` command

Always end the turn with the cd line in its own fenced code block, on its own line, so it's one-click copy. Example:

```
cd /Users/derek/eBacon/Viper/.worktrees/derek-339224-ci4
```

No other text after that block. The user wants to grab it and paste into a fresh terminal.

If you started the new-worktree script in the background, note above the cd block that the Docker build is still running and the user can paste the cd as soon as the worktree dir lands (usually a few seconds). One short sentence, not a paragraph.

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
- **Customize this file freely.** It's your personal wrapper; you own it. The upstream Viper skill is the canonical thing and stays untouched.
