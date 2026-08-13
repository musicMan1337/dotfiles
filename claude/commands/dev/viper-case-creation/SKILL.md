---
name: dev:viper-case-creation
description: Generate reviewable SQL scripts that create or extend Viper cases (dbo.cases / dbo.EmployeeToDo / dbo.t_folder), written to /private/tmp/viper-sql/ as dry-run scripts you run yourself in SSMS. Three modes, simple (one standalone case, raw SQL written inline), project (a new project case + N linked child cases + N linked todos, via the bundled python generator), and extend (add cases to, reschedule, or recategorize an existing project, inline SQL). NEVER executes SQL. Triggers on, create viper case, create a viper case, project case, case with todos, viper-case-creation, bulk cases, security findings case, make a project case with child cases, generate case sql, insert into dbo.cases, add cases to a project, schedule a project, project timeline sql, reschedule project cases.
model: sonnet  # authoring + light judgment; schema knowledge is baked into this file and the generator. Re-check tier on new model gen per TIERS.md.
---

# dev:viper-case-creation

Generate **SQL scripts** that create Viper cases in the `cases` / `EmployeeToDo` / `t_folder` schema. The scripts are written to the global temp dir **`/private/tmp/viper-sql/`** (never into a repo), are **dry-run by default** (wrapped in a transaction that ROLLS BACK unless `@Commit = 1`), and the user reviews + runs them in SSMS.

**This skill never executes SQL against any database.** It only writes reviewable `.sql` files. The user runs them. Do not offer to run them via a SQL MCP; the `sql-server` / `viper-stage` MCPs are SELECT-only anyway and writes are out of scope here by design.

## Three modes

Pick based on what the user wants:

1. **simple**: one standalone case. Write the raw SQL yourself, inline, using the template below. No python. Use when the user wants a single case (a bug, a task, one finding).
2. **project**: a NEW project case + N child cases + N todos. Build an input file and run the bundled generator `scripts/generate_project_cases.py`. Use when the user has a list of items (findings, tasks, sub-bugs) that should each become a case linked under one project.
3. **extend**: add cases to, or reschedule, an **existing** project. The generator cannot do this; write the SQL inline. See "Extending an existing project" below.

If the mode is ambiguous, ask: one case, a new project with several linked child cases, or additions to a project that already exists?

## Output rule

Every script goes to `/private/tmp/viper-sql/<slug>.sql`. The generator does this automatically (slug derived from the project name). For simple mode, write the file there yourself with a sensible slug (e.g. `/private/tmp/viper-sql/fix_export_timeout.sql`). After writing, print the absolute path and stop — the user opens and runs it in SSMS. Do not echo the whole script back inline.

## Safety wrapper (both modes)

Every script must have this shape so a run is a no-op until the user opts in:

```sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Commit BIT = 0;   -- set to 1 to persist
BEGIN TRAN;
  -- INSERTs
  -- verification SELECTs (so the user sees what would be created)
IF @Commit = 1 COMMIT ELSE ROLLBACK;
```

Running as-is previews the result sets and rolls back. The user reviews, sets `@Commit = 1`, and re-runs to persist.

## Verified schema facts (encode these; do NOT re-derive them)

These are verified against the live Viper Stage schema (via the `viper-stage` MCP), last re-verified **2026-08-11**. Trust them; don't go re-query the DB to "confirm." One exception: if you are about to write a column that is NOT listed here, `describe_table` it first. The auto-generated knowledge doc for `dbo.EmployeeToDo` is missing its planning columns, so `get_context` alone will mislead you.

### dbo.cases

- `CaseID` is an IDENTITY column. For a parent/project case capture it with `SET @ProjectCaseId = SCOPE_IDENTITY();` right after its INSERT.
- **`dbo.cases` has a trigger (`tr_Cases_Indexed`), so you CANNOT use `OUTPUT ... INTO`** on inserts. Insert child cases **one per row in a `WHILE` loop** and capture each with `SET @childId = SCOPE_IDENTITY();` immediately after. That is what the generator does. Do not use a `MAX(CaseID)` watermark and re-select; it is fragile under concurrency and unnecessary.
- A **project** case is marked `DevStatus = 'Project'`. Child cases use `DevStatus = 'In Discussion'`.
- **`CaseProject` is NOT the project link.** It is a legacy free-text label (7296 rows, still written as recently as 2026-06-24, 95 distinct values, **zero** of which match any `DevStatus='Project'` case title). Setting it is harmless but groups nothing. **The parent/child link lives in `dbo.EmployeeToDo`: `Item` = parent `CaseID`, `ItemType='Case'`, `LinkedCaseId` = child `CaseID`.** A child case row has no column pointing at its parent.
- `CaseImpact` ∈ {Low, Medium, High} — this is the severity/priority.
- `CaseType`: use the impact word (e.g. `'High'`). `DevCaseType`: `'Bug'`.
- `MilestoneId` = the `FolderId` of a milestone folder (see below).
- Set these to non-null sane values: `Client`, `CaseClient`, `AssignedTo`, `Creator`, `DateCreated = GETDATE()`, `CaseTitle`, `CaseDescription`, `CommunicateLevel = 'None'`, `PublicYn = 0`, `InternalConfidential` (1 for security-sensitive cases, else 0).

### The project board model (parent case columns)

A project case carries its board config in these columns. 269 project cases exist; 161 have categories.

- `ProjectCategories`: **JSON array** declaring the board's category columns: `[{"name":"Repo Snout Integration","sort":0,"color":null},...]`. A todo appears in a column by matching `EmployeeToDo.Category` to a `name` here **as an exact string**.
- `ProjectStartDate`, `ProjectTargetDate`: `date`. The project timeline.
- `ProjectStatus`, `ProjectStatuses`, `ProjectCustomDates`, `ProjectCustomFields`: board config, JSON in the plural ones. Leave alone unless asked.

**The generator does not write `ProjectCategories`.** If you pass per-item categories, the todos get a `Category` string that the parent never declares. Either set `ProjectCategories` on the parent to the distinct item categories in the same script, or expect the board not to group them. When adding a category to an existing project, read the current JSON and append; never blind-overwrite (guard the UPDATE on the exact expected value, so a board edited in the app makes the script skip instead of clobber).

### Milestones (dbo.t_folder)

Milestone folders are children of `dbo.t_folder` `FolderId 491` (`Name = 'Milestones'`). **Each milestone folder's `FolderId` IS the `cases.MilestoneId`.** Resolve by name:

```sql
DECLARE @MilestoneId INT;
SELECT @MilestoneId = FolderId FROM dbo.t_folder WHERE Name = @Milestone AND ParentId = 491;
```

e.g. `'Q3 2026'` → `1159`. **If the lookup returns NULL, leave `@MilestoneId` NULL and add a clearly-commented manual-set line. Never invent a milestone id.**

### dbo.EmployeeToDo (the todo table)

- `Item` = the parent (project) `CaseID` as a varchar; `ItemType = 'Case'`. **This is the only parent link that exists.**
- `AssignedTo`, `Priority` ∈ {Low, Medium, High, Urgent}, `Status` (use `'To Do'`), `Category`, `Tags`.
- `LinkedCaseId` + `LinkedCaseTitle` link the todo to a case. **A raw INSERT bypasses the app's `#<caseid>` text-parser, so set `LinkedCaseId` / `LinkedCaseTitle` columns directly.** Also put `#<caseid>` in the Title for display, but the columns are what actually create the link.
- **Planning columns live here, not on the case** (all missing from the auto-generated knowledge doc; verified by `describe_table` 2026-08-11): `StartDate` + `DueDate` (`date`), `SortOrder` (`int`, 0-based **within a category**), `Effort` (`varchar(50)`), `Dependencies` (`varchar(max)`, free text), plus `CompletedBy`, `CompleteDate`, `VoidDate`, `FolderId`, `LinkedDocumentId`. A schedule belongs on the todos; `cases.DueDate` is a single date with no start, effort, or ordering.
- `Effort` is NULL on every todo of the most recent project, so there is no in-use vocabulary. If you write it, say so in the script header so the user can drop it if the app expects an enum.
- Title format is inconsistent in live data: the app writes `Case #<id>`, the generator writes `#<id> <title>`. Match whatever the project you are adding to already uses.

## Simple mode — raw SQL template (write this inline)

Fill in the values from what the user asked for. One `INSERT INTO dbo.cases` inside the dry-run wrapper, then a verification SELECT.

```sql
/**********************************************************************
 * Viper case: <one-line summary>
 * SAFE BY DEFAULT: rolls back unless @Commit = 1.
 * Generated by dev:viper-case-creation. Review before committing.
 **********************************************************************/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Commit BIT = 0;   -- <== set to 1 to persist

/* Optional milestone. Delete this block (and MilestoneId below) if none. */
DECLARE @MilestoneId INT;
SELECT @MilestoneId = FolderId FROM dbo.t_folder WHERE Name = 'Q3 2026' AND ParentId = 491;
-- If @MilestoneId is NULL here, the milestone name didn't resolve; set by hand or leave NULL.

BEGIN TRAN;

DECLARE @CaseId INT;
INSERT INTO dbo.cases
    (Client, AssignedTo, DateCreated, Creator, CaseTitle, CaseDescription,
     CaseType, CaseClient, CaseImpact, DevStatus, DevCaseType, MilestoneId,
     PublicYn, CommunicateLevel, InternalConfidential)
VALUES
    ('TAGClient', 'TAGClient-NellisD', GETDATE(), 'TAGClient-NellisD',
     'CASE TITLE HERE', 'CASE DESCRIPTION HERE',
     'High', 'TAGClient', 'High', 'In Discussion', 'Bug', @MilestoneId,
     0, 'None', 0);
SET @CaseId = SCOPE_IDENTITY();

SELECT @CaseId AS NewCaseId, @MilestoneId AS MilestoneId;
SELECT CaseID, CaseTitle, AssignedTo, CaseImpact, DevStatus, MilestoneId
FROM dbo.cases WHERE CaseID = @CaseId;

IF @Commit = 1
BEGIN
    COMMIT TRAN;
    PRINT 'COMMITTED case ' + CAST(@CaseId AS VARCHAR(20)) + '.';
END
ELSE
BEGIN
    ROLLBACK TRAN;
    PRINT 'DRY RUN - rolled back. Review, set @Commit = 1, re-run to persist.';
END
```

Escape any single quotes in title/description by doubling them (`'` → `''`).

## Project mode — build input + run the generator

1. Gather the project params and the list of items from the user.
2. Write an input file. Preferred: JSON matching `examples/project-input.example.json`:

   ```json
   {
     "project": {"name":"...", "client":"TAGClient", "creator":"TAGClient-NellisD",
                 "assignee":"TAGClient-NellisD", "impact":"High", "todo_priority":"High",
                 "milestone":"Q3 2026", "confidential": true, "description":"..."},
     "items": [ {"title":"...","description":"...","category":"...","tags":"..."} ]
   }
   ```

   Put the input file in the scratchpad dir (it's an intermediate, not an artifact), not in `/private/tmp/viper-sql/`.

3. Run the generator (it writes the `.sql` to `/private/tmp/viper-sql/<slug>.sql`):

   ```bash
   python3 ~/.claude/commands/dev/viper-case-creation/scripts/generate_project_cases.py --json /path/to/input.json
   ```

   CSV alternative — a CSV of items (`title,description,category,tags`) plus project params as flags:

   ```bash
   python3 .../generate_project_cases.py --csv items.csv \
     --name "Q3 Security Hardening" --milestone "Q3 2026" --impact High --todo-priority High
   ```

   Useful flags: `--out <path>`, `--client`, `--creator`, `--assignee`, `--impact`, `--todo-priority`, `--milestone`, `--description`, `--confidential` / `--no-confidential`. CLI flags override JSON values.

4. Print the output path the generator reported. Done.

## Extending an existing project (mode 3)

The generator only builds a new project. To add to one that exists, write inline SQL in the standard dry-run wrapper.

1. **Read the project first.** Get the parent's `ProjectCategories`, `MilestoneId`, `ProjectStartDate`/`ProjectTargetDate`, then its children via the todos:

   ```sql
   SELECT t.RowId, t.LinkedCaseId, t.Category, t.SortOrder, t.Priority, t.StartDate, t.DueDate, c.CaseTitle, c.DevRanking
   FROM dbo.EmployeeToDo t LEFT JOIN dbo.cases c ON c.CaseID = t.LinkedCaseId
   WHERE t.Item = '<parentCaseId>' AND t.ItemType = 'Case' AND t.VoidDate IS NULL
   ORDER BY t.Category, t.SortOrder;
   ```

2. **Match the existing rows' conventions exactly**, don't apply this file's defaults: copy `CaseClient`, `InternalConfidential`, `MilestoneId`, `FolderId`, `CommunicateLevel` and the Title format from the siblings. A new case that looks different from its 20 siblings reads as a mistake.
3. **New cases**: one INSERT each + `SCOPE_IDENTITY()`, then one `EmployeeToDo` INSERT per case with `Item` = parent CaseID and the right `Category` / `SortOrder`.
4. **Orphan todos are a real failure mode.** A todo whose `LinkedCaseId` points at a CaseID that does not exist renders as a dead item (observed on project 354820: two todos pointing at never-created cases). To repair, create the real case and UPDATE the todo's `LinkedCaseId`, `Title`, and `LinkedCaseTitle`. Always include this check in the verification block, expecting zero rows:

   ```sql
   SELECT t.RowId, t.Title, t.LinkedCaseId
   FROM dbo.EmployeeToDo t LEFT JOIN dbo.cases c ON c.CaseID = t.LinkedCaseId
   WHERE t.Item = '<parentCaseId>' AND t.VoidDate IS NULL AND c.CaseID IS NULL;
   ```

5. **Bulk reschedule / rerank**: stage the plan in a `DECLARE @Sched TABLE (CaseId INT PRIMARY KEY, Category, SortOrder, StartDate, DueDate, Effort, Dependencies, SeqRank)`, then one `UPDATE ... FROM ... JOIN @Sched` for `dbo.cases` (`DevRanking`, `DueDate`) and one for `dbo.EmployeeToDo`. Rows whose CaseIDs are created in the same script go into `@Sched` in a second INSERT, using the `SCOPE_IDENTITY()` variables.
6. **`DevRanking` direction is unverified.** Write it as execution order with 1 = first, say so in the header, and include the one-line inversion UPDATE the user can run if the app sorts the other way.
7. **Editing existing descriptions**: append an idempotent block guarded by `AND CaseDescription NOT LIKE '%<marker>%'` so a second run is a no-op. For surgical changes use `REPLACE(CaseDescription, '<exact old sentence>', '<new>')` and capture a match-count flag **before** the UPDATE so the preview shows whether the string actually matched. `CaseDescription` is HTML.
8. Don't hoist `@@ROWCOUNT` into a `DECLARE` initializer (`DECLARE @n INT = @@ROWCOUNT`). Declare the counters up front and assign with `SET` right after the statement you are measuring.

## Gotchas

- **Never run the SQL.** This skill writes files only. Even if a SQL MCP is connected, the user runs the script in SSMS themselves. The whole point is a reviewable, dry-run-by-default artifact.
- **`/private/tmp/viper-sql/`, not the repo.** These scripts contain no secrets but live outside any git repo on purpose (they reference prod-shaped data and are one-off operational scripts). Never write them under the Viper checkout.
- **No `OUTPUT ... INTO` on dbo.cases.** The `tr_Cases_Indexed` trigger makes `OUTPUT INTO` fail. Insert one row at a time and capture `SCOPE_IDENTITY()` immediately; that is what the generator does (per-row `WHILE` loop). Don't "optimize" it into an OUTPUT clause, and don't reintroduce a `MAX(CaseID)` watermark.
- **Set `LinkedCaseId` directly, don't rely on `#<caseid>` in text.** A raw INSERT skips the app parser that turns `#123` into a link. Putting `#123` in the Title is display-only; the actual link is the `LinkedCaseId` / `LinkedCaseTitle` columns.
- **Never invent a `MilestoneId`.** Resolve it by folder name under parent 491. If it doesn't resolve, leave NULL with a commented manual-set line and tell the user the milestone name didn't match a folder.
- **Child case ids aren't known until commit.** In dry-run the child cases roll back, so the preview ids are provisional, and IDENTITY values are consumed even on rollback, so the committed run assigns different ones. That's fine: every link is made through the `SCOPE_IDENTITY()` variable inside the same transaction, so it is correct either way. Say this in the script header so the user doesn't chase the id difference.
- **Item titles must be unique in project mode.** The generator hard-errors on duplicates (`scripts/generate_project_cases.py`); disambiguate them. (Its inline rationale, "joined back by Title," is stale, the loop links by `SCOPE_IDENTITY()`, but the check is real and duplicate titles are ambiguous for humans reading the board anyway.)
- **Escape single quotes.** In simple-mode inline SQL, double any `'` in user text. The generator handles this for you.
- **`@Commit = 0` by default is not optional.** Never ship a script with `@Commit = 1` baked in. The user flips it after reviewing the preview result sets.

## Files

- `scripts/generate_project_cases.py`: project-mode generator (JSON or CSV in, dry-run `.sql` out).
- `examples/project-input.example.json`: a 2-item project input to copy.
