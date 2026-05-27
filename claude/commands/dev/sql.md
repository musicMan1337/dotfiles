---
name: dev:sql
description: Post-commit workflow for the eBacon SQL repo. Verifies the working tree is clean, refreshes local `master` (so the diff baseline is correct), then runs the MassScriptBuilder against the current branch to emit numbered SQL scripts the user can paste into SSMS. Saves the user from hunting down every changed file by hand. Triggers on: build mass scripts, mass script builder, sql mass build, run sql build, generate sql scripts, post-commit sql, /dev:sql.
model: opus
---

# /dev:sql

Personal helper for the SQL repo (`/Users/derek/eBacon/SQL`). The MassScriptBuilder tool diffs the current branch against `master` and emits numbered SQL files into `MassScriptBuilder/<Branch>/<slug>/`. This skill wraps the pre-flight (clean tree + fresh master) and the build invocation, so the user just has to open the output folder and run the scripts in SSMS.

## Constants

- **SQL repo:** `/Users/derek/eBacon/SQL`
- **Builder dir:** `/Users/derek/eBacon/SQL/MassScriptBuilder`
- **Build command:** `pnpm run build` (the underlying script is `node builder.js`; the user may say "npm run dev" or similar, but the actual package.json script is `build`)
- **Diff baseline:** `master` (per `builder.js` line ~48: `git diff --name-only master...HEAD`). If local `master` is stale, the diff misses or includes wrong files.
- **Output:** numbered SQL files (`1 - <name>.sql`, `2 - <name>.sql`, ...) plus `_template.js`, written into `MassScriptBuilder/<BranchPrefix>/<rest-of-branch>/`.

---

## Step 1: Verify cwd is the SQL repo

```bash
cd /Users/derek/eBacon/SQL && pwd && git rev-parse --abbrev-ref HEAD
```

If the user is on `master`, stop and tell them: this skill is meant to be run from a feature branch with commits to package up.

## Step 2: Verify working tree is clean

```bash
git status --porcelain
```

- **Clean:** proceed.
- **Dirty:** uncommitted SQL changes will not be picked up by the builder (it diffs against `master` via `git diff`, which compares commits). Stop and ask:
  1. Commit now via `/git:commit` then continue
  2. Proceed anyway (the diff will only reflect committed work)
  3. Abort

Use numbered options per the global rule.

## Step 3: Refresh local `master` without leaving the feature branch

```bash
git fetch origin master:master
```

This updates the local `master` ref to match `origin/master` without checking it out. The feature branch stays as the working tree. If the fetch fails because `master` is currently checked out (shouldn't happen since Step 1 gated that), fall back to:

```bash
current=$(git rev-parse --abbrev-ref HEAD)
git checkout master && git pull --ff-only && git checkout "$current"
```

If `master` has diverged (non-fast-forward), tell the user and stop. Do not rebase or merge silently.

## Step 4: Ensure builder deps are installed

```bash
cd /Users/derek/eBacon/SQL/MassScriptBuilder
test -d node_modules || pnpm install
```

The repo uses pnpm (lockfile is `pnpm-lock.yaml`). Only install if `node_modules` is missing; don't re-install on every run.

## Step 5: Run the builder

```bash
cd /Users/derek/eBacon/SQL/MassScriptBuilder && pnpm run build
```

Surface stdout/stderr to the user. The builder prints what it included and where it wrote to. If it errors (missing template entry, file not found, etc.), surface the error verbatim, do not retry, and let the user decide what to do.

## Step 6: Locate the output and print a copy-pasteable path

The branch name is `<Prefix>/<rest>`, e.g. `Derek/344451-FileDateGating`. The output lands at `MassScriptBuilder/<Prefix>/<rest>/`. Compute the absolute path:

```bash
branch=$(cd /Users/derek/eBacon/SQL && git rev-parse --abbrev-ref HEAD)
echo "/Users/derek/eBacon/SQL/MassScriptBuilder/$branch"
```

End the turn with:

1. One short line: how many numbered SQL files were emitted (count `[0-9]*.sql` in the output dir).
2. A fenced code block with the absolute path, so the user can `cd` into it or open it in Finder:

```
/Users/derek/eBacon/SQL/MassScriptBuilder/Derek/344451-FileDateGating
```

No further text after the block.

---

## Gotchas

- **Diff baseline is `master`, not `origin/master`.** `builder.js` uses `git diff --name-only master...HEAD` against the **local** `master` ref. If that ref is stale, the file list is wrong (either missing recently-merged files or duplicating files that are already on master). Step 3 is non-negotiable.
- **The script is `build`, not `dev`.** `package.json` only defines `build`. If the user says "run dev," translate to `pnpm run build`.
- **Uncommitted changes are silently excluded.** `git diff master...HEAD` only sees committed work. Step 2 surfaces this so the user understands why a file might be missing from the output.
- **Branch must follow `<Prefix>/<rest>` convention** for the output path to be predictable. If the branch is unconventional (no slash, weird casing), the builder may still produce output but the path won't match the formula in Step 6. Fall back to printing the build's own stdout to find the path.
- **The `_template.js` file inside the output dir is the include manifest.** If the user re-runs the builder later, they may want to edit it to reorder or exclude files. Mention this only if asked, not by default.
- **Do not commit the output.** `MassScriptBuilder/<branch>/` artifacts are run against the DB and not source. The repo's `.gitignore` should cover it; if it doesn't, that's a repo bug, not something this skill fixes.
- **One stack at a time.** Not applicable here. SQL builder is local-only, no Docker, no port conflicts.
- **Customize this file freely.** Personal wrapper; you own it.
