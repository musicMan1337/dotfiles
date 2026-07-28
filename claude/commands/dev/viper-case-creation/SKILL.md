---
name: dev:viper-case-creation
description: Generate reviewable SQL scripts that create Viper cases (dbo.cases / dbo.EmployeeToDo / dbo.t_folder), written to /private/tmp/viper-sql/ as dry-run scripts you run yourself in SSMS. Two modes, simple (one standalone case, raw SQL written inline) and project (a project case + N linked child cases + N linked todos, via the bundled python generator). NEVER executes SQL. Triggers on, create viper case, create a viper case, project case, case with todos, viper-case-creation, bulk cases, security findings case, make a project case with child cases, generate case sql, insert into dbo.cases.
model: sonnet  # authoring + light judgment; schema knowledge is baked into this file and the generator. Re-check tier on new model gen per TIERS.md.
---

# dev:viper-case-creation

Generate **SQL scripts** that create Viper cases in the `cases` / `EmployeeToDo` / `t_folder` schema. The scripts are written to the global temp dir **`/private/tmp/viper-sql/`** (never into a repo), are **dry-run by default** (wrapped in a transaction that ROLLS BACK unless `@Commit = 1`), and the user reviews + runs them in SSMS.

**This skill never executes SQL against any database.** It only writes reviewable `.sql` files. The user runs them. Do not offer to run them via a SQL MCP; the `sql-server` / `viper-stage` MCPs are SELECT-only anyway and writes are out of scope here by design.

## Two modes

Pick based on how many cases the user wants:

1. **simple** — one standalone case. Write the raw SQL yourself, inline, using the template below. No python. Use when the user wants a single case (a bug, a task, one finding).
2. **project** — a project case + N child cases + N todos. Build an input file and run the bundled generator `scripts/generate_project_cases.py`. Use when the user has a list of items (findings, tasks, sub-bugs) that should each become a case linked under one project.

If the mode is ambiguous, ask: one case, or a project with several linked child cases?

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

These are verified against the live Viper schema. Trust them; don't go re-query the DB to "confirm."

### dbo.cases

- `CaseID` is an IDENTITY column. For a parent/project case capture it with `SET @ProjectCaseId = SCOPE_IDENTITY();` right after its INSERT.
- **`dbo.cases` has a trigger (`tr_Cases_Indexed`), so you CANNOT use `OUTPUT ... INTO`** on inserts. To capture the ids of a bulk child INSERT: take a watermark `DECLARE @MaxBefore INT = (SELECT ISNULL(MAX(CaseID),0) FROM dbo.cases);` before the insert, then re-select `WHERE CaseProject = @ProjectName AND CaseID > @MaxBefore`.
- A **project** case is marked `DevStatus = 'Project'`. Child cases use `DevStatus = 'In Discussion'`.
- `CaseProject` is a **free-text project NAME** (not an id) that groups child cases. Set each child's `CaseProject` = the project case's name.
- `CaseImpact` ∈ {Low, Medium, High} — this is the severity/priority.
- `CaseType` — use the impact word (e.g. `'High'`). `DevCaseType` — `'Bug'`.
- `MilestoneId` = the `FolderId` of a milestone folder (see below).
- Set these to non-null sane values: `Client`, `CaseClient`, `AssignedTo`, `Creator`, `DateCreated = GETDATE()`, `CaseTitle`, `CaseDescription`, `CommunicateLevel = 'None'`, `PublicYn = 0`, `InternalConfidential` (1 for security-sensitive cases, else 0).

### Milestones (dbo.t_folder)

Milestone folders are children of `dbo.t_folder` `FolderId 491` (`Name = 'Milestones'`). **Each milestone folder's `FolderId` IS the `cases.MilestoneId`.** Resolve by name:

```sql
DECLARE @MilestoneId INT;
SELECT @MilestoneId = FolderId FROM dbo.t_folder WHERE Name = @Milestone AND ParentId = 491;
```

e.g. `'Q3 2026'` → `1159`. **If the lookup returns NULL, leave `@MilestoneId` NULL and add a clearly-commented manual-set line. Never invent a milestone id.**

### dbo.EmployeeToDo (the todo table)

- `Item` = the parent (project) `CaseID` as a varchar; `ItemType = 'Case'`.
- `AssignedTo`, `Priority` ∈ {Low, Medium, High, Urgent}, `Status` (use `'To Do'`), `Category`, `Tags`.
- `LinkedCaseId` + `LinkedCaseTitle` link the todo to a case. **A raw INSERT bypasses the app's `#<caseid>` text-parser, so set `LinkedCaseId` / `LinkedCaseTitle` columns directly.** Also put `#<caseid>` in the Title for display, but the columns are what actually create the link.

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

## Gotchas

- **Never run the SQL.** This skill writes files only. Even if a SQL MCP is connected, the user runs the script in SSMS themselves. The whole point is a reviewable, dry-run-by-default artifact.
- **`/private/tmp/viper-sql/`, not the repo.** These scripts contain no secrets but live outside any git repo on purpose (they reference prod-shaped data and are one-off operational scripts). Never write them under the Viper checkout.
- **No `OUTPUT ... INTO` on dbo.cases.** The `tr_Cases_Indexed` trigger makes `OUTPUT INTO` fail. Use the `@MaxBefore` watermark + re-select pattern. The generator already does this; don't "optimize" it into an OUTPUT clause.
- **Set `LinkedCaseId` directly, don't rely on `#<caseid>` in text.** A raw INSERT skips the app parser that turns `#123` into a link. Putting `#123` in the Title is display-only; the actual link is the `LinkedCaseId` / `LinkedCaseTitle` columns.
- **Never invent a `MilestoneId`.** Resolve it by folder name under parent 491. If it doesn't resolve, leave NULL with a commented manual-set line and tell the user the milestone name didn't match a folder.
- **Child case ids aren't known until commit.** In dry-run the child cases roll back, so the ids you see are provisional. That's fine — the todos are joined to child cases inside the same transaction by the watermark re-select, so links are correct on the real (committed) run too.
- **Item titles must be unique in project mode.** The todos are joined back to child cases by Title. The generator hard-errors on duplicate titles; disambiguate them.
- **Escape single quotes.** In simple-mode inline SQL, double any `'` in user text. The generator handles this for you.
- **`@Commit = 0` by default is not optional.** Never ship a script with `@Commit = 1` baked in. The user flips it after reviewing the preview result sets.

## Files

- `scripts/generate_project_cases.py` — project-mode generator (JSON or CSV in, dry-run `.sql` out).
- `examples/project-input.example.json` — a 2-item project input to copy.
