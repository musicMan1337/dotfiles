---
name: dev:sql
description: Develop and test stored procedures in the SQL repo with live execution via sqlsrv MCP. Triggers on: sql, work in sql, sql dev, sproc, stored procedure, work on a procedure
allowed-tools: mcp__sqlsrv__*, Bash, Read, Edit, Glob, Grep
---

# SQL Dev Session

You are working in the eBacon SQL repo (`~/eBacon/SQL/`). The sqlsrv MCP gives you live access to the stage database — you can execute stored procedures, inspect tables, and verify results without leaving the editor.

## Repo Layout

- `Source/` — SQL source organized by database/area (Core, Production, DEV, Utilities, etc.)
- `Schema/` — Database schema definitions
- `SchemaUpdates/` — Migration scripts
- `Tests/` / `testRunner/` — Test infrastructure
- `sprocSchemas/` — Stored procedure schema docs
- `queries/` — Ad-hoc queries

Sproc files are usually named after the procedure, but not always. Use Grep to find procedures by name.

## Autonomous Dev Loop

This is the core workflow. Repeat as needed:

1. **Read the sproc** — Find and read the procedure file in `~/eBacon/SQL/Source/`.
2. **Make changes** — Edit the SQL file.
3. **Execute the sproc** — Call `sqlsrv_execute_sproc` with the procedure name and parameters to test your changes.
4. **Inspect results** — The tool returns all result sets. Check that output matches expectations.
5. **Iterate** — If results are wrong, read the output, adjust the SQL, and re-execute.

## Tools Reference

| Tool | Purpose |
|------|---------|
| `sqlsrv_execute_sproc` | Execute a stored procedure with parameters |
| `sqlsrv_list_tables` | List all configured tables |
| `sqlsrv_describe_table` | Get table schema and columns |
| `sqlsrv_query` | SELECT from configured tables (read-only) |

### Executing a Sproc

Call `sqlsrv_execute_sproc` with:
- `sproc` — procedure name (e.g., `"dbo.usp_GetEmployeeDetails"`)
- `params` — object where keys are `@parameter` names and values are the argument values

```json
{
  "sproc": "dbo.usp_GetEmployeeDetails",
  "params": {
    "@EmployeeId": 12345,
    "@IncludeHistory": 1
  }
}
```

The MCP builds the query safely with parameterized inputs — no injection risk. Multiple result sets are returned as separate arrays.

### Debugging Without the Query Tool

You don't need `sqlsrv_query` to debug procedure logic. Instead, add temporary `SELECT` statements inside the sproc to emit intermediate values:

```sql
-- Debug: check what we're about to insert
SELECT @EmployeeId AS DebugEmployeeId, @CalcAmount AS DebugCalcAmount

-- Debug: show contents of temp table before join
SELECT * FROM #tempResults
```

Then execute the sproc and read the extra result sets in the output. **Remove debug SELECTs when done.**

This is more useful than querying tables because you see the data *mid-execution* — after transforms, before writes.

## Gotchas

- **Stage database.** The sqlsrv MCP connects to `bsqldev.tagpay.com`. You're hitting real stage data. Writes from sproc execution will persist — be careful with INSERT/UPDATE/DELETE procedures. Prefer read-heavy sprocs for testing, or use known safe test entity IDs.
- **Sproc must exist on the server.** Editing a `.sql` file locally doesn't deploy it. If you're modifying a sproc, it needs to be deployed to stage before `execute_sproc` will see your changes. Ask the user about their deployment workflow if unsure.
- **Multiple result sets.** Many eBacon sprocs return multiple result sets (e.g., header + line items + totals). The MCP returns all of them — check each one, not just the first.
- **Parameter naming.** Always include the `@` prefix in parameter keys. The MCP expects `"@ParamName"`, not `"ParamName"`.
- **NULL vs missing.** If a sproc parameter is optional with a default, omit it from `params` entirely rather than passing `null`. The MCP only sends parameters you include.
- **Filenames don't always match.** Sproc `dbo.usp_GetSomething` might be in a file called `GetSomething.sql` or `usp_GetSomething.sql` or something else entirely. Always grep, don't guess.
- **PII is filtered from query results.** The `sqlsrv_query` tool hides columns like SSN, pay rates, addresses. If you need to verify a write to a PII column, use a debug SELECT inside the sproc instead.
- **Sub-sproc calls.** eBacon sprocs frequently call other sprocs. If output is unexpected, trace the call tree — the bug might be in a nested procedure. Search for `EXEC` or `EXECUTE` inside the sproc body.
