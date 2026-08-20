---
name: dev:viper-worktree
description: Personal wrapper around Viper's `viper-dev-worktree` skill. Two modes. Mode A (default, run from anywhere): Phase 1 picks/creates a worktree and kicks Docker into the background (static app-only build by default; hotreload is explicit opt-in), Phase 2 looks up the case in SQL Server and writes `PLAN_<slug>.md` into the worktree root, then cd's the session into the worktree and starts implementing. Mode B (run with no args from inside a worktree): reads the worktree's `PLAN_*.md`, confirms with the user, and starts implementing. Triggers on: viper worktree picker, list viper worktrees, pick a worktree, start a viper worktree, switch viper worktrees, my worktree wrapper, viper plan from case, /dev:viper-worktree.
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
3. A Docker question (start now / build-only / skip). Multiple stacks may run concurrently; this wrapper does NOT stop other stacks.
4. A "build the image but leave it stopped" path, so the image is warm but RAM is free.
5. **Phase 2:** SQL Server case lookup and `PLAN_<slug>.md` write into the worktree root.
6. The session `cd`s itself into the worktree and continues straight into the Mode B implementation flow (no `cd` command handed back to paste).

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

# Build workflow

There are two ways to get frontend changes in front of the user. The default is the **static** path; hotreload is an **explicit opt-in**.

## DEFAULT: static build (app container + one-shot host build)

Use this unless the user explicitly asked for hotreload. No opt-in needed; this is what you do silently.

A worktree's `hotreload` container runs `webpack --watch` and sits resident at **~3 GB each**. Two or three of those simultaneously exhaust the Docker VM and get OOM-killed (exit 137, `OOMKilled=false` is the Docker-Desktop VM-OOM signature). So the default is **app container only**, and you rebuild the frontend with a one-shot **host** build when needed.

**Bring-up:** `docker compose up -d app`. Starts Apache/PHP only; the `hotreload` profile (enabled in the provisioned `.env` via `COMPOSE_PROFILES=hotreload`) is skipped because the service is named explicitly.

**The one-shot host build.** Run from the worktree root, on the **host** (uses your Mac's RAM + the host `node_modules` symlink, costs the Docker VM nothing):

```bash
NODE_ENV=development node ./buildScripts/deleteBuildFiles.js \
  && NODE_ENV=development node ./node_modules/webpack/bin/webpack --progress
```

This is the real "`npm run dev`" the user means, minus the npm wrapper. Do NOT use `npm run dev` directly: npm fires the `predev` lifecycle hook, whose `checkLockfileDrift.js` aborts on pre-existing drift in the shared main-checkout `node_modules` (storybook/simple-git minor bumps) and the `&&` chain stops before webpack runs. The container hotreload command bypasses `predev` for the same reason; the host command above mirrors it. Never `npm install` to "fix" the drift; it mutates the shared `node_modules` every worktree symlinks to. Host node must satisfy `package.json` engines (currently node `^24.15.0`). Build takes ~50-60 s.

**Auto-update.** The `app` service bind-mounts the worktree (`.:/app:cached`), so a finished host build is served on the **next browser refresh**, no container restart. (Exception: a changed PHP file behind opcache may need `docker compose restart app` to flush; frontend bundles never do.)

## OPT-IN: hotreload (only when the user asks for it)

Hotreload is **not** automatic. The user must explicitly ask ("turn on hotreload", "I'm iterating React, give me live reload", etc.). When they do, set it up for that worktree:

```bash
docker compose --profile hotreload up -d
```

(or plain `docker compose up -d`, which honors the `.env` profile). This gives live rebuild + BrowserSync auto-refresh. Once a worktree is on hotreload, the watcher rebuilds on save, so you skip the one-shot host build for that worktree. Don't run hotreload in more than one or two worktrees at once (the ~3 GB resident cost is what OOMs the VM).

## When the agent builds + hands back (static worktrees)

End each **code-change block** with one fresh host static build before handing back to the user, i.e. once you're done editing and returning, NOT after every individual edit. Run it regardless of what the block touched (backend-only sessions included; a stale or missing build breaks the shell, see the Step 4 initial-build note). Only skip when the worktree is running hotreload (the watcher already rebuilds).

Verify the build actually completed before handing back: webpack must exit 0 and report `compiled successfully` (or emit fresh bundle files). A half-finished or interrupted build serves stale/truncated bundles, which present in the browser as an **infinite refresh loop with `Uncaught SyntaxError: Unexpected token ';'`**. That symptom means rebuild, not debug-the-JS.

**Rebuild after any merge/pull into the worktree.** Merging master (or pulling) changes source without touching built bundles; hand back only after a fresh one-shot build, don't wait for the user to hit the stale-bundle error.

Then **print the URL** so the user can open it. See the next section for how to construct it correctly.

## Printing the worktree URL (do this right, or it "doesn't work")

Each worktree binds a unique host port and is named `<slug>.localhost`. The **only** URL that actually serves the app is the named host **with its port**:

```
http://<DC_APP_HOST>:<DC_APP_PORT>
```

Both values live in the worktree's `.env` (`DC_APP_HOST=<slug>.localhost`, `DC_APP_PORT=<port>`). **Read them from `.env`, never reconstruct the host from the branch/slug and never drop the port.** From the worktree root:

```bash
echo "http://$(grep -E '^DC_APP_HOST=' .env | cut -d= -f2):$(grep -E '^DC_APP_PORT=' .env | cut -d= -f2)/"
```

Print that exact string. Prefer it over `http://localhost:<port>`, named URLs are the whole point (cookie isolation per host, and a readable tab instead of a wall of `localhost:84xx` tabs).

**Why a bare `http://<slug>.localhost` (no port) fails / looks broken:** there is **no reverse proxy** in this setup. The slug name only resolves to loopback via RFC 6761; it does not map to the container's port. Without `:<DC_APP_PORT>` the request hits loopback `:80`, where no Viper container listens. On this Mac a stray system Apache answers `:80` with a 45-byte default page, so you get a misleading `200 OK` on a blank/wrong page instead of an honest connection refusal. Always append the port. (`.localhost` resolves IPv6-first to `::1`, but Docker Desktop publishes on both stacks, so the named-host + port form connects fine.)

---

# SQL changes in a worktree batch

A Viper feature often also touches the eBacon SQL repo (sprocs, views, schema, data fixes). **Never edit/branch/commit SQL in the shared main checkout (`/Users/derek/eBacon/SQL`) from inside a Viper worktree.** Route ALL SQL work through **`/dev:sql`**, which sets up an isolated SQL worktree mirroring this Viper branch name, commits, pushes, and builds.

When a worktree code batch touches SQL and you're closing it out for review, `/dev:sql` must run the MassScriptBuilder in **both** modes (it already does this end-to-end; invoking it satisfies the requirement):

1. **Regular mode, in the SQL worktree** (HEAD = the branch): emits the tracked `_template.js` ordering manifest that travels with the branch.
2. **Targeted-branch mode, from the SQL repo root** (`/Users/derek/eBacon/SQL`, not on the branch): reads the branch's committed tree from the shared local git store and emits the **gitignored** `__template.js` plus the numbered `.sql` scripts the user pastes into SSMS.

So: every time SQL changes land in a worktree batch, the close-out is not "I edited the sproc" but "the SQL branch is committed, pushed, and built at the SQL repo root, here's the script path." The Viper worktree holds PHP/JS; its SQL counterpart lives under `/Users/derek/eBacon/SQL/.worktrees/<slug>`.

---

# Testing uploaded files

Stub corpus: `/Users/derek/eBacon/exampleFiles/`. One `example.<ext>` per file type plus `rejected-example.exe` / `rejected-example.js` for the rejection path. The bytes are throwaway; only the extension (and the MIME derived from it) matters.

Whitelists differ per stack, which changes what a test should expect: CI3 `uploadFile` allows `jpg jpeg png doc docx xls xlsx gif msg pdf zip txt xml csv tif pptx ppt mp3 iif md`; CI4 `Shared/Files/FileType` allows that set plus `rtf` and `sql`. `example.eml` is in the corpus but whitelisted by neither, so it is a third rejection case. Both stacks cap at 35000 KB.

## Recreating the file for an existing `t_document` row

Uploaded bytes never leave prod/stage, so any local screen that downloads, previews, thumbnails, or merges an existing document 404s (or fatals) until a file exists at that row's path. `t_document.filePath` is web-relative, rooted at the worktree's `public/`:

- Host: `<worktree>/public/<filePath>`. Container: `/app/public/<filePath>` (same file via the bind mount). Always create it on the host.
- New-convention paths are `uploaded/<client>/<entity>/<itemType>_<item>_<YmdHis>_<fileTitle>.<ext>`, but legacy rows carry arbitrary shapes and are read verbatim. Copy `filePath` out of the DB; never derive it.

From the worktree root:

```bash
P='uploaded/CLIENT/CLIENT-user/Case_351958_20260101120000_Contract.pdf'   # t_document.filePath, verbatim
mkdir -p "public/$(dirname "$P")" && cp "/Users/derek/eBacon/exampleFiles/example.${P##*.}" "public/$P"
```

Keep the extension the row's path already has: `FileType` / `sendFile()` derive the download MIME from it, and an unlisted extension throws rather than serving. `public/uploaded/*` is gitignored (only `index.php` + `web.config` tracked), so dummies never reach a diff. Worktree bootstrap mirrors gitignored paths from the main checkout, so anything planted in main's `public/uploaded/` follows into every future worktree; plant in the worktree to keep it local.

CI4's phpunit environment roots uploads at `writable/uploaded-test` instead (`ENVIRONMENT === 'testing'`), so files planted for browser testing are invisible to the test suite and vice versa.

## Feeding upload endpoints

The same corpus is your upload payload. Browser path: hand the file input the absolute `exampleFiles` path (Claude in Chrome's `file_upload`). Direct curl against the worktree, with a session cookie:

```bash
curl -b "PHPSESSID=<id>" -F "userfile[]=@/Users/derek/eBacon/exampleFiles/example.pdf" \
  "http://$DC_APP_HOST:$DC_APP_PORT/<controller>/<method>"
```

CI3 multi-upload reads `$_FILES["userfile"]` (array form) and re-keys each file to `singlefile` internally; CI4 `UploadLibrary::upload()` takes `UploadedFile`s off the request, field name per endpoint. Round-trip a success case by reading back the new `t_document` row and confirming the bytes landed at its `filePath`; for `rejected-example.*` expect a refusal, not a saved row.

---

# Closing out a code-change batch (ready for review)

When you finish a batch of edits in a worktree and are handing back to the user for review, do this close-out so the user has everything they need to verify, the app reflects your changes and any SQL is built and pushed. Run only the parts the batch touched.

1. **Frontend / app up to date in Docker.** On the static default, run the one-shot host build (see "DEFAULT: static build") after every code-editing session, frontend-touched or not. On hotreload, the watcher already did it. (PHP opcache exception still applies: a changed PHP file may need `docker compose restart app`.) The app container bind-mounts the worktree, so the build is live on next refresh.
2. **Print the named URL.** Emit `http://$DC_APP_HOST:$DC_APP_PORT` read from the worktree `.env` (see "Printing the worktree URL"), so the user can open the right app.
3. **SQL built + pushed.** If the batch touched SQL, run `/dev:sql` (both builder modes, above) so the branch is committed, pushed, and the numbered scripts are regenerated at the SQL repo root. Surface the output path.
4. **Verify the change.** Run `/verify` to drive the actual change through the app end-to-end, not just "the build compiled + URL printed"; this is the user-flow verification beat. Skip only when the diff has no runtime surface (docs/config/test-only); `/verify`'s own rule already handles that. If `/verify` surfaces a real failure, fix it (or report it) before proceeding; do not advance a broken change to the gate.
5. **Summarize what to review.** One short list: the URL to open, the SQL script path to run in SSMS (if any), and what changed. Don't bury it.
6. **Blast-radius gate.** Classify the change and apply policy:

   | Class | Viper signals | Policy |
   |---|---|---|
   | TINY / SMALL | copy, styling, config, localized single-feature logic | after `/verify` passes, offer to chain into `/dev:wrapup`; the user merges |
   | MEDIUM | multi-file logic, shared components, new endpoints/controllers | `/verify` + an explicit risk summary (what could break, blast radius) before offering wrapup; the user merges |
   | LARGE | SQL/schema, auth/session/permissions, payroll or money calc, migrations, broadly-imported core modules | HARD STOP. Do not offer to open a PR. Present the risks and require an explicit human "go" before anything proceeds |

   Every tier: **no auto-merge.** The user merges on GitHub, always.
7. **Offer close-out.** Per the gate result, offer numbered options: 1. run `/dev:wrapup` to close out (commit/push/PR/standup), 2. stop for manual review. LARGE must not auto-advance past step 6 without the explicit go.

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
- Multiple running stacks are fine (Docker resource limits raised). Note what's already running for the user's awareness, but do NOT offer to stop anything.

Cross-reference: each entry in `ls .worktrees/` is a candidate; annotate it with its container state.

### Step 2: Pick a worktree (Q1)

Use `AskUserQuestion`. Build options like this:

- One option per existing worktree, labelled `<slug>  [<state>]` where state is `running`, `stopped`, or `no-image`. Use `ls -1t` order so most-recently-touched comes first.
- One option `Create new worktree`.

If there are 4+ existing worktrees, show the top 3 + `Create new`, and mention in the question text: "N more not shown; pick Other and type the slug." The `AskUserQuestion` "Other" path is your escape hatch for slug typing.

If the user picks `Create new` (or types a non-existent slug as Other), follow up with a free-text prompt for the branch name. Follow Viper's branch convention `<Name>/<CaseId>-<description>` per the loaded upstream skill. Don't invent a CaseId; ask if absent.

### Step 3: Decide on Docker (Q2)

Use `AskUserQuestion`. Optionally note in the question text what else is already running (FYI only; other stacks are left alone).

Options (up to 4):

1. **Start Docker now.** Just brings up this worktree's stack; leaves any other running stacks untouched.
2. **Build only, leave stopped.** Image gets built so a future `docker compose up -d` is fast, but RAM is freed once the build finishes.
3. **Skip Docker entirely.** Only show this option for an *existing* worktree that already has a built image (`state == stopped`). For a new worktree, always build at minimum (per user preference: warm image, cold RAM).
4. *(omit if not applicable)*

### Step 4: Kick off Docker in background, then continue

**Existing worktree:**

- **Start Docker now:** default app-only — `cd /Users/derek/eBacon/Viper/.worktrees/<picked-slug> && docker compose up -d app` (`run_in_background: true`). Add hotreload only if the user asks (`docker compose --profile hotreload up -d`). See the "Build workflow" section above. Do NOT touch other running stacks.
- **Build only, leave stopped:**
  - If image exists (state was `stopped`): no-op, image is already built.
  - If no image (state was `no-image`): `cd <worktree> && docker compose build && docker compose down` (`run_in_background: true`).
- **Skip Docker:** nothing to do.

**New worktree:**

- Run `./bin/viper-new-worktree.sh <branch-name>` from `/Users/derek/eBacon/Viper`. This branches from `master` (override only if the user explicitly says so; see upstream skill `--from` rules), creates `.worktrees/<slug>/`, provisions ports, and runs `docker compose up -d --build`.
- "Start Docker now" needs no extra action: the script already brings the stack up. Leave other running stacks alone. NOTE: the script runs `docker compose up -d --build`, which honors the `.env` `hotreload` profile and brings hotreload up too. To hold the app-only default (see "Build workflow"), chain `; cd .worktrees/<new-slug> && docker compose stop hotreload` after the script unless the user asked for hotreload.
- If "Build only" was chosen: chain `; cd .worktrees/<new-slug> && docker compose down` after the script so the image is warm but RAM is free once the build finishes.
- **Always run the new-worktree script in the background** (`run_in_background: true`). The user does not want to wait. The worktree directory is created early in the script, so Phase 2 work below can proceed against the worktree root within a few seconds.
- **Always chain the initial frontend build** (the `npm run dev` static build; NOT hotreload) after the script, regardless of what the session plans to work on. A fresh worktree's `_build/` is empty, and the PHP shell view echoes the build manifest into an inline script: with no build, that renders `= ;` (browser: `Uncaught SyntaxError: Unexpected token ';'`) and the shell reload-loops. Backend-only sessions hit this the moment the user opens the URL. Use the one-shot host build from "DEFAULT: static build" (the predev-bypass chain, since raw `npm run dev` aborts on lockfile drift); background it with the rest of the chain: `; cd .worktrees/<new-slug> && NODE_ENV=development node ./buildScripts/deleteBuildFiles.js && NODE_ENV=development node ./node_modules/webpack/bin/webpack`.

### Step 4.5: Carry over gitignored local config (new worktrees only)

The new-worktree script checks out tracked files only; gitignored local config does NOT follow, and its absence surfaces later as confusing DB/connection errors. As soon as the worktree directory exists (poll briefly, the script creates it early), from the worktree root:

1. **Copy gitignored local config from the main checkout.** Known set: `public/application/config/database.php`. For each: if it exists in `/Users/derek/eBacon/Viper/` and not in the worktree, `cp` it over.
2. **Provision CI4 composer deps (`server/vendor/`).** If the worktree lacks `server/vendor/autoload.php`, copy it from main: `cp -R /Users/derek/eBacon/Viper/server/vendor <worktree>/server/vendor`. Why it's needed: `viper-new-worktree.sh` symlinks `node_modules` but never provisions `server/vendor`, and the `ci4` sidecar's on-start `composer install` FAILS on a fresh worktree because `composer.lock` requires `ext-gd` (mpdf) + `ext-zip` (openspout) which the ci4 Docker image doesn't enable. With no `vendor/`, every CI4 `/api/*` request fatals: `require(/app/server/vendor/autoload.php): Failed to open stream`. Copy (not symlink — a host-absolute symlink dangles inside the container, same as node_modules). Only valid when the worktree's `server/composer.lock` matches main's (branch off master, composer untouched) and main's vendor already has the locked packages. Systemic fix (not this wrapper's job): add gd/zip to `.docker/local/ci4/Dockerfile` so the container's own install succeeds. Verify after copy: `curl -s http://$DC_APP_HOST:$DC_APP_PORT/api/health` returns JSON, not a PHP fatal.
3. **Mirror the local dev patch in `public/application/config/config.php`.** The main checkout's working copy carries a local-only modification (an `&& false` clause near line 21 that skips a section for local dev). Check `git -C /Users/derek/eBacon/Viper diff -- public/application/config/config.php`; if the main checkout has that local diff and the worktree copy doesn't, apply the same one-line change to the worktree copy.
4. List everything copied/patched in the handoff summary. If a worktree later hits missing-DB-config or unexpected-section behavior, re-check this carry-over before debugging anything else.

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

### Step 8: cd into the worktree and continue into implementation

Do NOT print a `cd` command for the user to paste. Instead, **`cd` your own session into the worktree** and flow straight into the Mode B implementation steps. The Bash tool's working directory persists across calls, so this `cd` carries through the rest of the session:

```bash
cd /Users/derek/eBacon/Viper/.worktrees/<slug>
```

Then run the Mode B flow below in-line, starting at **Step B1.5** (rename the tab) since you already know the PLAN file you just wrote (skip the B1 lookup). Summarize the plan (B2) and confirm before coding (B3).

One caveat: if the new-worktree script is still bootstrapping in the background, the worktree directory may not exist yet. Poll briefly (up to ~10s) for the directory before `cd`-ing; the script creates it early. If after the poll it still isn't there, tell the user the build is still spinning up and offer to wait or proceed once it lands (numbered options).

Docker bring-up runs in the background and does not block this. The user can start reviewing the plan while the stack finishes coming up; the first URL print (after the first build) is when they'll actually open the app.

---

# Mode B: Implementation (already in a worktree, no args)

Reached either by the user `cd`-ing into the worktree and re-invoking with no args, or by Mode A Step 8 handing off in-session.

### Step B1: Locate the PLAN file

```bash
ls PLAN_*.md 2>/dev/null
```

- If exactly one match, that's the plan file.
- If zero matches, tell the user there's no `PLAN_*.md` in this worktree and offer to (1) re-run Mode A to generate one or (2) proceed without a plan. Numbered options.
- If multiple matches (unexpected), ask which to use.

### Step B1.5: Rename the terminal tab

Silently rename the tab per the global **Terminal Tab Renaming** convention in `~/.claude/CLAUDE.md` (one-liner and format live there), run from the worktree root.

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

On "Start coding", begin executing the plan tasks directly. Use TaskCreate to track milestones if the work has multiple discrete steps. Otherwise just start. When you finish a batch and hand back, run the "Closing out a code-change batch (ready for review)" checklist (frontend build + URL, SQL via `/dev:sql`, summary).

On "Refine the plan first", open the PLAN file in edit mode, ask what to change, write the changes, then re-confirm.

---

## Gotchas

- **Multiple stacks may run concurrently.** Docker resource limits were raised, so several Viper stacks running simultaneously is fine. NEVER auto-stop another worktree's stack to make room. `docker compose down` is only ever run against the stack the user explicitly asked to stop/teardown, never as a side effect of starting another. (Historically this wrapper enforced "one stack at a time" and OOM'd on stock Docker limits; that no longer applies.)
- **Slug vs branch.** `viper-new-worktree.sh` takes the **branch name** (e.g. `Derek/339224-CI4`), not the slug (`derek-339224-ci4`). The slug is auto-derived. Worktrees are listed by slug.
- **"Build only" is a post-action, not a flag.** `viper-new-worktree.sh` always does `docker compose up -d --build`. There is no `--no-up` flag. To leave a stack stopped, let the script finish then run `docker compose down`.
- **`docker compose down` without `-v`.** `-v` deletes the `viper-sessions` named volume, which wipes login state. Never use `-v` in this skill's flow.
- **`-app-1` is the canonical "running" signal.** Some worktrees only ship hotreload + sandbox; some have `ci4` containers. Check `app` to decide whether the stack is up. Don't trip on hotreload-only or sandbox-only states.
- **`AskUserQuestion` caps at 4 options.** Use the "Other" text-input escape for the 4+-worktrees case. Don't try to fit 5 worktrees into 4 buttons.
- **`viper-new-worktree.sh` defaults to branching from `master`.** Do not silently use a different ref. If the user says "from my current branch" or similar, pass `--from <ref> <branch>` explicitly and confirm before creating, per the upstream skill.
- **This skill never tears down.** If the user asks to remove a worktree, defer to the upstream `viper-dev-worktree` teardown flow. Teardown is destructive and has its own confirmation gates.
- **Leftover containers from removed worktrees.** If `docker ps -a` shows a `viper-worktree-<slug>-app-1` whose `.worktrees/<slug>/` directory no longer exists, mention it but don't auto-clean. The user may want to keep the image cached.
- **Phase 2 does not block Phase 1.** Docker kickoff is in the background. Run SQL + write PLAN concurrently, then `cd` into the worktree and continue into Mode B (do not block on the Docker build).
- **Default build is static; hotreload is opt-in.** Unless the user explicitly asks for hotreload, bring up `app` only and use the one-shot host webpack build after each code-change block. Only enable `--profile hotreload` when the user asks for live reload. See "Build workflow".
- **Always print the named URL WITH its port, read from `.env`.** The serving URL is `http://$DC_APP_HOST:$DC_APP_PORT` (both from the worktree's `.env`). Never reconstruct the host from the branch/slug and never emit a bare `http://<slug>.localhost` (no port): there's no reverse proxy, so a portless slug URL hits loopback `:80` and a stray system Apache answers with a blank 45-byte page (misleading `200 OK`). Prefer the named URL over `localhost:<port>` (cookie isolation + readable tab). See "Printing the worktree URL".
- **No case ID, no context = skip Phase 2.** Don't try to invent a case or prompt the user for direction. If they volunteered free-text context when creating the worktree, write a minimal context-only PLAN (Shape B) instead. Silence means skip.
- **PLAN file is ephemeral.** It lives only in the worktree. Rely on existing global/repo gitignore patterns; do not modify `.gitignore` or `.git/info/exclude` from this skill.
- **Mode B trigger is strict.** Only switch to Mode B when `pwd` is under `.worktrees/<slug>/` AND no args were passed. Any args mean the user wants Mode A behavior.
- **SQL changes go through `/dev:sql`, and build on close-out.** See "SQL changes in a worktree batch" and "Closing out a code-change batch". Never edit/branch/commit SQL in the shared main checkout from a Viper worktree; route it through `/dev:sql`, which builds both the worktree (`_template.js`) and root targeted-branch (`__template.js`) manifests. A batch that touched SQL isn't review-ready until that build has run and pushed.
- **Stale/incomplete bundles: infinite refresh + `Uncaught SyntaxError: Unexpected token ';'`.** Known recurring failure mode. Causes: interrupted/failed webpack build, or source merged/pulled without rebuilding. On this symptom, rerun the one-shot host build first; do not debug the JS. Rebuild proactively after every merge from master.
- **Rebuilt change "not taking effect": stale chunk-hash manifest.** After a successful rebuild, a plain refresh can still run the OLD app chunk: the PHP shell echoes a stale build manifest (opcache/include caching in the app container) and the browser serves the old-hash chunk from cache. Diagnose by comparing the loaded hash (`performance.getEntriesByType('resource')`) against `_build/` contents; if mismatched, `docker compose restart app` then hard reload (cmd+shift+R). Observed 2026-07-11 on case 351222.
- **Case-only renames + macOS bind mounts serve phantom stale files.** Docker Desktop bind mounts are case-insensitive; after a case-only rename (`Documents.php` vs `documents.php`) the container can keep serving the old-cased file, so PHP parse errors persist across edits that "should" have fixed them. Fix: `docker compose up -d --force-recreate app`. Avoid case-only renames; if one lands, force-recreate immediately instead of editing in circles.
- **Gitignored local config does not follow into new worktrees.** See Step 4.5; `database.php` missing or the `config.php` local patch absent is the first thing to check when a fresh worktree misbehaves.
- **CI4 `/api/*` fatals with `require(/app/server/vendor/autoload.php): Failed to open stream`.** A fresh worktree has no `server/vendor/` — `viper-new-worktree.sh` doesn't provision it, and the `ci4` container's on-start `composer install` fails because `composer.lock` needs `ext-gd` (mpdf) + `ext-zip` (openspout), absent from the ci4 image (`docker compose logs ci4` shows the platform-req failure). Fix per Step 4.5 item 2: `cp -R /Users/derek/eBacon/Viper/server/vendor <worktree>/server/vendor`. The app (CI3) works without it; only migrated CI4 endpoints break, so this often surfaces mid-task the first time a migrated `/api` path is hit. Systemic fix is gd/zip in `.docker/local/ci4/Dockerfile`.
- **Blast-radius gate is advisory + human-merge discipline, never auto-merge.** See "Closing out a code-change batch". The close-out gate classifies the change and gates the wrapup offer; it never merges. LARGE changes (SQL/auth/payroll) always stop for explicit human sign-off before anything proceeds.
- **Existing `t_document` rows have no bytes locally.** Download/preview/PDF paths against prod-copied rows 404 or fatal until a dummy file is planted at `<worktree>/public/<filePath>`; stub corpus at `/Users/derek/eBacon/exampleFiles/`. See "Testing uploaded files".
- **Customize this file freely.** It's your personal wrapper; you own it. The upstream Viper skill is the canonical thing and stays untouched.
