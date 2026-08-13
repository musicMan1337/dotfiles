---
name: dev:sql
description: Full workflow for the eBacon SQL repo. ALL SQL work (editing sprocs/views/migrations, committing, pushing, building) happens in an isolated git worktree of the SQL repo, NEVER in the shared main checkout. The skill sets up/locates the worktree, commits via /git:commit, pushes the branch, runs the MassScriptBuilder from the main repo root (PR-style diff vs origin/master) to emit numbered SQL scripts for SSMS, then emits pre/post verification test scripts (single UNION ALL result tab, pasteable RESULTS block) under queries/cc/tests/ and later parses the pasted results into a completion verdict. On request, appends a plain-text case-note INSERT (dbo.notes + log_case) to the post test script. Triggers on: sql work, edit sproc, change a view, sql migration, build mass scripts, mass script builder, sql mass build, run sql build, generate sql scripts, commit sql, push sql, post-commit sql, sql test script, verify sql change, parse test results, /dev:sql.
model: opus
---

# /dev:sql

Personal helper that owns the **entire** lifecycle of a change to the eBacon SQL repo (`/Users/derek/eBacon/SQL`): worktree → edit → commit → push → build. The MassScriptBuilder diffs a branch against `origin/master` (PR-style, fetched automatically) and emits numbered SQL files into `MassScriptBuilder/<Branch>/`, ready to paste into SSMS.

## Base behavior: build on every ready-for-review batch

**Whenever a batch of SQL changes is done and ready for the user to review, running the MassScriptBuilder is mandatory, not optional.** It's the close-out of every batch: commit + push + build so the numbered scripts the user pastes into SSMS always reflect the latest committed state. Don't hand a SQL batch back for review without a fresh build. The same close-out also emits the pre/post verification test scripts (Step 5).

### The two builder modes (same builder, two run contexts)

The builder runs in two complementary modes; this skill does **both** in a normal worktree flow:

- **Regular mode** (Step 1b): run *on the branch itself* (`node builder.js`, no arg, from a checkout/worktree whose HEAD = the branch). Reads the branch's current files, emits the tracked `_template.js` ordering manifest that travels with the branch.
- **Targeted-branch mode** (Step 4): run *from the main repo root*, which is NOT on the branch (`node builder.js "<branch>"`). It reads that branch's committed tree from the shared local git store via `git show <branch>:…` (worktrees share `.git`, so no checkout or network pull is needed; the branch just has to be committed, and Step 2 pushes it too), then emits the **gitignored** `__template.js` plus the numbered `.sql` scripts.

Both produce output under `MassScriptBuilder/<Branch>/`; the root targeted-branch run is the authoritative one whose numbered `.sql` files the user runs in SSMS.

## ⚠️ Hard rule: SQL work is ALWAYS done in a worktree

**Never edit, branch, commit, or push SQL in the main checkout (`/Users/derek/eBacon/SQL`).** The main checkout is a single shared working tree. Doing branch work there is unsafe and has bitten us:

- `git checkout -b` in the main checkout **carries another session's uncommitted changes onto your branch** (parallel tasks share that one tree).
- Switching the main checkout's HEAD (e.g. another task, or restoring master) **reverts your uncommitted edits in place**, silently losing work.
- Two tasks editing the same shared tree interleave and corrupt each other's diffs.

A dedicated worktree gives the branch its own isolated tree. The main checkout is touched for **exactly one thing**: running the builder (which lives only there and reads any branch's *committed* tree via `git show`). If a SQL change is part of a Viper feature, it gets its **own SQL worktree** that mirrors the Viper branch name.

## Constants

- **Main SQL repo (build ONLY from here, never edit here):** `/Users/derek/eBacon/SQL`
- **Worktree root:** `/Users/derek/eBacon/SQL/.worktrees/<slug>` (slug = branch lowercased, `/`→`-`)
- **Builder dir:** `/Users/derek/eBacon/SQL/MassScriptBuilder`
- **Build command:** `pnpm run build` (underlying script is `node builder.js`; if the user says "npm run dev", translate to `build`)
- **Diff baseline:** `origin/master`, handled inside `builder.js` (`getBaseRef()` best-effort fetches `origin/master` then diffs `origin/master...<ref>`). PR-accurate; no manual master refresh needed.
- **Output:** numbered SQL files (`1 - <name>.sql`, ...) plus a manifest, written into `MassScriptBuilder/<Branch>/`. Manifest is `_template.js` for the checked-out branch (tracked; committed on the branch in Step 1b), `__template.js` (gitignored) when building a different branch via the branch arg.
- **Template-replay build:** `node builder.js --template <path>` (npm script `build:template`) ignores the git diff and rebuilds just the files listed in `<path>/(_|__)template.js`, pulling each body from the current `origin/master` tree. Committing `_template.js` in Step 1b is what makes this replay possible later.
- **Schema update file naming.** Schema-modifying SQL (DDL: `CREATE/ALTER TABLE`, indexes, new columns, one-time backfills) goes in `SchemaUpdates/DN/` as `DN_<caseid>_<ShortDescription>.sql` (e.g. `SchemaUpdates/DN/DN_344451_FileDateGating.sql`). The builder orders these first. Non-schema changes (SP/view edits, data updates) go in the per-user folder (`Derek/<descriptive-name>.sql`), not `SchemaUpdates/`.
- **Test scripts dir (gitignored scratch, in the MAIN checkout, not the worktree):** `/Users/derek/eBacon/SQL/queries/cc/tests/`, named `<caseid>_<snake_cased_description>_pre.sql` / `_post.sql` (see Step 5).

---

## Step 0: Land in a SQL worktree (do this BEFORE any SQL edit)

Resolve where we are and the target branch:

```bash
MAIN=/Users/derek/eBacon/SQL
here=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || echo "")
echo "here=$here"
git -C "$MAIN" worktree list
```

Pick the branch name. If this SQL change supports a Viper worktree, **mirror that worktree's branch** (e.g. Viper `Derek/345279-FolderInheritance` → SQL branch `Derek/345279-FolderInheritance`). Otherwise follow `Derek/<CaseId>-<ShortDescription>`. Then:

```bash
branch="Derek/345279-FolderInheritance"          # <- set this
slug=$(printf '%s' "$branch" | tr 'A-Z/' 'a-z-')
wt="$MAIN/.worktrees/$slug"
```

Create or reuse the worktree (handles both "branch is new" and "branch already exists"):

```bash
git -C "$MAIN" fetch origin master --quiet
if [ -d "$wt" ]; then
  echo "worktree exists: $wt"
elif git -C "$MAIN" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$MAIN" worktree add "$wt" "$branch"                 # existing branch
else
  git -C "$MAIN" worktree add -b "$branch" "$wt" origin/master # new branch off master
fi
echo "SQL worktree: $wt"
```

**All SQL editing + committing happens in `$wt` from here on.** Tell the user the worktree path so any manual edits land there too.

### Recovery: edits were already made in the main checkout

If SQL files were mistakenly edited/branched in `$MAIN` (e.g. `here` == `$MAIN` and the tree is dirty, or a feature branch was created in main), STOP and surface it. The clean fix is to carry the committed branch into a worktree and reset main back to master:

1. If the work is already committed on a branch in main: `git -C "$MAIN" worktree add "$wt" "$branch"`, then `git -C "$MAIN" checkout master` (this also reverts any stray uncommitted tree state back to master). Continue in `$wt`.
2. If the work is uncommitted in main: ask the user before moving anything (stashing/`worktree add` choices) — do not silently relocate uncommitted edits, they may be intermixed with a parallel session's changes.

Use numbered options. Never proceed by committing in the main checkout.

## Step 1: Commit in the worktree (via /git:commit)

Make sure the intended edits live in `$wt`, then commit them there. Invoke `/git:commit` with the worktree as the working repo (or `git -C "$wt"` for a trivial one-file commit per the trivial-commit rule). Verify nothing unrelated is staged:

```bash
git -C "$wt" status --porcelain
```

If the tree shows files you did not author (a parallel session's leak), do not include them — surface and stop.

## Step 1b: Generate + commit the ordering manifest (`_template.js`) on the branch

Run the builder **inside the worktree** (where HEAD = your branch) to emit the
tracked `_template.js` manifest, then commit just that file so the ordered list
of changed `.sql` files travels with the branch. This is the artifact `build:template`
mode later replays from. (The main-root run in Step 4 uses the branch arg and so
writes the *gitignored* `__template.js`; only a checked-out-branch run produces
the tracked single-underscore `_template.js`.) Skip this step if there is no
worktree (`$wt` unset).

The worktree needs the builder's deps. Reuse main's rather than installing a
second copy per worktree:

```bash
wtb="$wt/MassScriptBuilder"
test -d "$MAIN/MassScriptBuilder/node_modules" || (cd "$MAIN/MassScriptBuilder" && pnpm install)
test -e "$wtb/node_modules" || ln -s "$MAIN/MassScriptBuilder/node_modules" "$wtb/node_modules"
MSB_NO_FETCH=1 sh -c "cd '$wtb' && node builder.js"   # no arg = HEAD = this branch -> _template.js
```

`MSB_NO_FETCH=1` is safe because Step 0 already fetched `origin/master`. Stage
ONLY the manifest (the `.sql` output and `__template.js` are gitignored; the
single-underscore `_template.js` is not):

```bash
git -C "$wt" add "MassScriptBuilder/$branch/_template.js"
git -C "$wt" status --porcelain MassScriptBuilder
```

Commit it via `/git:commit` (worktree as the repo); a trivial one-file manifest
commit may use `git -C "$wt"` directly per the trivial-commit rule. If the
manifest is empty or unchanged from HEAD, skip the commit and say so.

## Step 2: Push the branch

```bash
git -C "$wt" push -u origin "$branch" 2>&1 | tail -8
```

The builder diffs `origin/master`, and pushing keeps origin authoritative for the branch. Surface the push result.

## Step 3: Ensure builder deps are installed

```bash
test -d /Users/derek/eBacon/SQL/MassScriptBuilder/node_modules || (cd /Users/derek/eBacon/SQL/MassScriptBuilder && pnpm install)
```

Only install if `node_modules` is missing.

## Step 4: Run the builder (always from the main repo root, pass the branch)

The builder lives only in `$MAIN` and reads the branch's **committed** tree via `git show`, so it never touches the worktree and never needs the branch checked out in main. Call `node builder.js` directly, NOT `pnpm run build -- "$branch"`: pnpm forwards `--` as the literal target arg and the build fails with `ambiguous argument 'origin/master...--'`.

```bash
cd /Users/derek/eBacon/SQL/MassScriptBuilder && node builder.js "$branch"
```

Surface stdout/stderr verbatim. It prints the base ref, target, what it included, and where it wrote. On error (missing template entry, bad ref, etc.), surface verbatim, do not retry, let the user decide.

## Step 5: Emit pre/post verification test scripts

Every batch that changes DB behavior ships with test scripts the user runs in SSMS/DataGrip around the numbered change scripts. Write them to the gitignored scratch dir `/Users/derek/eBacon/SQL/queries/cc/tests/`:

- **Naming:** `<caseid>_<snake_cased_description>_pre.sql` and `<caseid>_<snake_cased_description>_post.sql` (case id + description from the branch, e.g. `353920_approval_pending_indexes_post.sql`; NoCase branches drop the case id and use the snake_cased description alone).
- **`_pre` only when applicable:** emit it when the change alters existing behavior worth baselining (perf fix, output-preserving refactor, index change) so pre-vs-post can be compared. New-object-only changes get just `_post`. Skip both for manifest-only or comment-only batches.
- **Run order (state it in each file header):** `_pre` BEFORE the numbered change scripts, `_post` after.

**Single result tab is the contract.** Structure each file so the user copies ONE grid:

- Each check is a SELECT emitting the same column shape, e.g. `check_name, expected, actual, detail`, with every value column CAST to NVARCHAR (or SQL_VARIANT) so heterogeneous checks UNION ALL cleanly; compute pass/fail in SQL where possible.
- Setup (DECLAREs, temp tables, captured counts) goes above; the file ends in a single UNION ALL query, `ORDER BY check_name`.
- If genuinely irreducible to one query (mid-script state, INSERT-EXEC capture, incompatible shapes), group into the FEWEST possible UNION ALL blocks and state the expected result-tab count in the file header.

Header comment per file: case id, branch, when to run, "copy the grid WITH HEADERS and paste it into the RESULTS block". Footer:

```sql
/* ==== RESULTS: paste grid output WITH HEADERS below this line ====

==== END RESULTS ==== */
```

### Case note insert (ON USER REQUEST ONLY)

When the user asks (e.g. "make a case note stating the problem and solution"), append a `CASE NOTE` section to the bottom of the `_post` file (above the RESULTS block), inside its own comment block so whole-file execution never runs it; the user selects the statements inside and executes the selection:

```sql
/* ==== CASE NOTE: select the statements below and run them manually ====
INSERT INTO dbo.notes (Client, Itemtype, Item, Creator, Note)
VALUES ('<client>', 'Case', '<caseid>', '<user entity>', '<note text>');

INSERT INTO dbo.log_case (CaseID, Client, RecordUser, Attribute, oldValue, newValue)
VALUES ('<caseid>', '<client>', '<user entity>', 'Note Added', '', '<note text>');
==== END CASE NOTE ==== */
```

- **Note text is PLAIN TEXT, never HTML.** Concise problem + solution, outcome-focused; double any embedded single quotes (`''`).
- The pair mirrors `noteActionPaywiz` (`NoteID` is identity, `CreatedDate` defaults; the `log_case` row is what puts "Note Added" in case history). Skip the email-workflow part of the sproc; a manual insert intentionally doesn't notify.
- `Client` comes from the case row (`SELECT Client FROM cases WHERE caseid = <caseid>`); `Creator`/`RecordUser` is the user's entity. If either is unknown, ask, never guess.

## Step 6: Locate the output and print copy-pasteable paths

End the turn with:

1. One short line: how many numbered SQL files were emitted (count `[0-9]*.sql` in the output dir) and which test scripts exist, with run order.
2. A fenced code block with the absolute paths (builder output dir, then each test script), nothing after it:

```
/Users/derek/eBacon/SQL/MassScriptBuilder/Derek/344451-FileDateGating
/Users/derek/eBacon/SQL/queries/cc/tests/344451_file_date_gating_pre.sql
/Users/derek/eBacon/SQL/queries/cc/tests/344451_file_date_gating_post.sql
```

## Step 7: Ingest pasted RESULTS, format, verdict

When the user says results are pasted (or pastes them in chat):

1. Read each test file's RESULTS block and parse the raw grid (tab-separated or aligned text, headers in the first row).
2. Replace the raw paste inside the comment block with an aggregated, aligned table (pre-vs-post deltas where a `_pre` exists) so the file becomes the readable record; touch nothing above the RESULTS block.
3. Report the verdict: per-check pass/fail against the case's success criteria, and whether the batch satisfies case completion. Surface any check that can't be mapped to a criterion instead of guessing; a missing or partial paste means "cannot verdict yet", not a fail.

---

## Gotchas

- **Worktree, always.** Editing/branching/committing SQL in the main checkout is the one thing this skill exists to prevent. See the hard rule above.
- **Baseline is `origin/master`, automatic.** `builder.js` best-effort fetches and diffs `origin/master...<ref>`. To diff against something else: `MSB_BASE=<ref>`. To skip the fetch in a tight loop: `MSB_NO_FETCH=1`.
- **Build from main, pass the branch.** `MassScriptBuilder/` exists only in `$MAIN`. `pnpm run build -- "$branch"` pulls file contents from that branch's committed tree via `git show`, so the worktree need not be the cwd.
- **The script is `build`, not `dev`.** `package.json` only defines `build`.
- **Uncommitted changes are silently excluded.** The diff only sees committed work — another reason Step 1's commit must land in the worktree before building.
- **`.worktrees/` is ignored by the search.** The builder skips `.worktrees`, `.git`, and `node_modules` when resolving template filenames, so worktree copies never leak in.
- **Manifest naming.** Checked-out branch → tracked `_template.js`; branch arg → gitignored `__template.js`. Mention only if asked.
- **Commit the manifest, in the worktree (Step 1b).** The tracked `_template.js` is generated by running the builder from inside the worktree (HEAD), not the branch-arg run in main (which yields the gitignored `__template.js`). Reuse main's `node_modules` via a symlink so each worktree doesn't carry its own copy. Commit only `MassScriptBuilder/<branch>/_template.js`.
- **Do not commit the `.sql` output.** `MassScriptBuilder/<branch>/*.sql` is run against the DB, not source; `.gitignore` covers `**/*.sql`.
- **Test scripts are scratch, not source.** `queries/cc/` is gitignored; write them in the MAIN checkout's `queries/cc/tests/`, never in the worktree, never committed.
- **UNION ALL type alignment.** CAST every value column to NVARCHAR in every branch of the union; mismatched types across branches is the #1 way the single-tab contract breaks.
- **Cleanup.** Remove a finished SQL worktree with `git -C "$MAIN" worktree remove "$wt"` once the branch is merged; the branch on origin is preserved.
- **Customize this file freely.** Personal wrapper; you own it.
