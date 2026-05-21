---
description: Generate a runnable T-SQL seed script that populates the eBacon case "Testing Instructions" screen for the current case via createProcess + addUpdateInstruction SPs. Use after wrapping up feature work, or any time the user asks to "write test instructions for the case", "seed testing instructions", "generate test SQL for this branch", "case test instructions script", or "populate testing instructions for case #X".
---

# Case Testing Instructions — SQL Seed

The eBacon case system has a "Testing Instructions" tab. The UI calls `createProcess` (one row in `t_ViperProcess` per processType) followed by repeated `addUpdateInstruction` (rows in `t_Instruction`, ordered by `sortOrder`). This command produces a T-SQL script that does the same thing directly, so a feature owner can seed thorough instructions without filling out the UI by hand.

## What to produce

A single T-SQL block that:
1. Declares variables for `@Case`, `@Client`, `@Entity`, and location labels at the top
2. Calls `createProcess` once per `processType` ('ViperChange' for FE/PHP work, 'SQLChange' for SP work — include only the ones the branch actually touched)
3. Captures the new process id via `INSERT INTO @ProcResult TABLE(id INT) EXEC ...` (SP returns id via `SELECT SCOPE_IDENTITY()`; OUTPUT params don't work here)
4. Calls `addUpdateInstruction NULL, @ProcessID, '<step>', <sortOrder>, NULL` for each step, sortOrder starting at 1 and ascending
5. Ends with a verify SELECT against `t_ViperProcess` and `t_Instruction` so the user can confirm what landed

## Required values — DO NOT GUESS, THESE ARE NON-OBVIOUS

| Field | Value | Why |
| --- | --- | --- |
| `@itemType` | **`'Case'`** | The FE source has `'ProcessCase'` in one spot, but that's for the file-association call, not process rows. Real `t_ViperProcess` data uses `'Case'`. Using `'ProcessCase'` will INSERT successfully but the rows won't render in the case UI. |
| `@client` | **`'TAGClient'`** | The case fetcher falls back to `$this->WebpayUser->client` when the FE omits the `client` param, and the TAG-internal Webpay user resolves to `'TAGClient'`. Anything else (including `'DemoTest'`) silently won't render. |
| `@processType` | `'ViperChange'` or `'SQLChange'` | One record per type. These are the only two values the FE filters on (`processCollection.findWhere({processType: 'SQLChange'})`). |
| `@mobileRequiredYn` | `0` (almost always) | Only set to `1` if the feature requires mobile QA. |

## How to figure out the case number

Pull from the current git branch. The convention is `Author/<CASE#>` or `Author/<CASE#>-suffix`.

Run `git branch --show-current` (in the Viper or SQL repo — both branches share the case number). Strip the author prefix and the suffix to get the digits.

If the branch doesn't follow that convention, ask the user for the case number explicitly.

## How to figure out what to test

Inspect the work to ground the instructions in actual changes — don't hallucinate. Most useful signals, in order:

1. **Conversation context** if this command is invoked at the end of a working session — what was built, what bugs were fixed, what the user verified. This is usually the richest source.
2. **Commits on the branch**: `git log --oneline master..HEAD` in both the Viper repo and the SQL repo. Each commit's subject is a feature surface to cover.
3. **Diff stat**: `git diff master..HEAD --stat` — file paths reveal the surface area (UI, controller, model, SPs).
4. **PR descriptions** if PRs already exist: `gh pr view --json title,body`.

Synthesize into clear, numbered test steps. Aim for outcome-oriented language ("Expect: drawer closes, the Wed renders with the change") not implementation language ("verify the SP returned 200"). Include DB-level checks the user can run alongside UI checks where useful.

If both Viper and SQL changes exist, produce TWO blocks in one script: one `ViperChange` process for the UI/FE/PHP work, one `SQLChange` process for the SP/schema work. Cross-link them by case number — they're independent rows.

## Template

```sql
SET NOCOUNT ON;

-- Test instructions seed for Case <CASE> — <feature title>.
-- Mirrors the case Testing Instructions UI:
--   createProcess  → one row in t_ViperProcess per processType
--   addUpdateInstruction × N → rows in t_Instruction, ordered by sortOrder

DECLARE @Case   VARCHAR(255) = '<CASE>';
DECLARE @Client VARCHAR(255) = 'TAGClient';
DECLARE @Entity VARCHAR(255) = '<TAG entity, e.g. TAGClient-NellisD>';
DECLARE @LocViper VARCHAR(255) = '<UI breadcrumb, e.g. Scheduling > Scheduler > Event Drawer>';
DECLARE @LocSql   VARCHAR(255) = '<SP set, e.g. Scheduling v2 SPs (detach / split / void)>';

DECLARE @ProcResult TABLE (id INT);
DECLARE @ViperPID INT, @SqlPID INT;

-- ════════════════════════════════════════════════════════════════════
-- ViperChange (FE + PHP)
-- ════════════════════════════════════════════════════════════════════
INSERT INTO @ProcResult
EXEC dbo.createProcess
    @location         = @LocViper,
    @description      = '<high-level summary of what this process tests>',
    @mobileRequiredYn = 0,
    @processType      = 'ViperChange',
    @item             = @Case,
    @itemType         = 'Case',
    @client           = @Client,
    @entity           = @Entity;

SET @ViperPID = (SELECT TOP 1 id FROM @ProcResult ORDER BY id DESC);
DELETE FROM @ProcResult;

EXEC dbo.addUpdateInstruction NULL, @ViperPID,
    '<step 1: usually a PRE-REQ — what data/state to set up first>',
    1, NULL;

EXEC dbo.addUpdateInstruction NULL, @ViperPID,
    '<step 2: action + expected outcome + any DB-level check>',
    2, NULL;

-- ... more steps ...

-- ════════════════════════════════════════════════════════════════════
-- SQLChange (SPs)
-- ════════════════════════════════════════════════════════════════════
INSERT INTO @ProcResult
EXEC dbo.createProcess
    @location         = @LocSql,
    @description      = '<high-level summary of SP-level tests>',
    @mobileRequiredYn = 0,
    @processType      = 'SQLChange',
    @item             = @Case,
    @itemType         = 'Case',
    @client           = @Client,
    @entity           = @Entity;

SET @SqlPID = (SELECT TOP 1 id FROM @ProcResult ORDER BY id DESC);
DELETE FROM @ProcResult;

EXEC dbo.addUpdateInstruction NULL, @SqlPID,
    '<SP test step 1>',
    1, NULL;

-- ... more steps ...

-- Verify
SELECT processID = id, processType, location, item, itemType, client
FROM t_ViperProcess
WHERE item = @Case AND itemType = 'Case' AND voidDate IS NULL
ORDER BY id DESC;

SELECT processID, sortOrder, LEFT(description, 100) AS preview
FROM t_Instruction
WHERE processID IN (@ViperPID, @SqlPID)
ORDER BY processID, sortOrder;
```

## Gotchas

- **`itemType='ProcessCase'` looks correct but is wrong.** The FE source references `'ProcessCase'` in `app.js` and the file-association controller code, but those calls are for `l_FileAssociation`, not process rows. Test instruction rows use `itemType='Case'`. Verified by `SELECT itemType, COUNT(*) FROM t_ViperProcess WHERE voidDate IS NULL GROUP BY itemType` — `Case` has ~1900 rows, `ProcessCase` has zero in stable production data. If you find yourself reaching for `ProcessCase`, stop.
- **`client='DemoTest'` (or any test-client value) makes rows invisible.** The case UI filters by the logged-in user's client. TAG employees view through `client='TAGClient'`. Even when the feature itself is being tested against DemoTest, the *case* metadata must be `TAGClient`.
- **`createProcess` returns its id via `SELECT SCOPE_IDENTITY()`**, not an OUTPUT parameter. You must capture it with `INSERT INTO @tbl EXEC dbo.createProcess ...`. Trying to use `OUTPUT INSERTED.id` or an output param will fail.
- **Two process records per case is normal** when both UI and SP work exists. The FE expects exactly one row per `processType` — duplicates inside a single processType cause the screen to pick one and silently ignore the others. Don't generate two `ViperChange` records.
- **`description` is varchar(8000)** on `t_Instruction` — be detailed. Outcomes + verification queries belong in one row, not split across multiple.
- **`addUpdateInstruction` insert skips rows where description is empty** (see SP source `IF LEN(@description) > 0`). Filler / placeholder rows are silently dropped — write real steps from the first row.
- **If the user already ran a seed and rows aren't appearing**, first check what's there: `SELECT id, item, itemType, client, processType FROM t_ViperProcess WHERE item = '<case#>' AND voidDate IS NULL`. The fix is usually `UPDATE t_ViperProcess SET itemType='Case', client='TAGClient' WHERE id IN (...)` — no need to re-seed.

## Process

1. Determine the case number (branch parse, fall back to asking the user).
2. Determine which processType buckets to produce — `ViperChange` if there are FE/PHP commits, `SQLChange` if there are SP commits, both if both. Use `git log master..HEAD` in each repo to decide.
3. Synthesize the instruction list from the conversation and commits. Group steps logically: pre-reqs first, then golden paths, then edge cases, then regression checks, then bad-data safety.
4. Emit the script as a single fenced ```sql``` block in chat so the user can copy-paste into SSMS / their runner.
5. Tell the user briefly what runtime to target (typically `Stage`), and remind them they can re-run safely — the SPs will append new rows; to wipe stale entries first, `UPDATE t_ViperProcess SET voidDate = GETDATE() WHERE item = '<case#>' AND voidDate IS NULL`.

Do not write the script to a file unless the user asks. The default delivery is inline in chat.
