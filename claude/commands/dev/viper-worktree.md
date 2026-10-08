---
name: dev:viper-worktree
description: Personal wrapper around Viper's `viper-dev-worktree` skill, runnable from anywhere. The repo skill owns the flow (worktree picker, `./viper worktree` stack bring-up, case lookup into `PLAN_<slug>.md`, resume from the PLAN inside a worktree); this wrapper adds personal close-out (`/verify`, `/dev:sql` builds, blast-radius gate, `/dev:wrapup` offer), tab renaming, and the local upload stub corpus. Triggers on: viper worktree picker, list viper worktrees, pick a worktree, start a viper worktree, switch viper worktrees, my worktree wrapper, viper plan from case, /dev:viper-worktree.
model: opus
---

# /dev:viper-worktree

Personal layer over `/Users/derek/eBacon/Viper/.claude/skills/viper-dev-worktree/SKILL.md`. **Read that file first and follow it end to end**; it is the source of truth for the flow and the `./viper` CLI. Everything below either fills in a value the repo skill leaves generic or adds a step after one of its steps. Where they disagree on tooling, the repo skill wins; fix this file.

`$ARGUMENTS` passes straight through to the repo skill's "Task for this run".

## Fixed values

- **Main checkout:** `MAIN=/Users/derek/eBacon/Viper`. Works from any cwd, including outside the repo; run `./viper worktree` from `$MAIN`.
- **SQL MCP for the case lookup and 2FA codes:** `mcp__sql-server__*` (load via tool search).

## Additions to the repo flow

### On entering Resume (repo Step 6 or R1)

Silently rename the terminal tab per the global **Terminal Tab Renaming** convention in `~/.claude/CLAUDE.md`, run from the worktree root.

### Never stop another stack

Starting or creating a worktree never runs `down` on any other one. Leftover containers whose `.worktrees/<slug>/` is gone: mention, don't clean.

### Teardown

Not this command's job: hand off to `/dev:viper-worktree-cleanup`.

## Close-out (replaces the repo skill's "Closing out a batch")

Run only the parts the batch touched:

1. **Rebuild** per the repo skill (`./viper up`, or `./viper assets` to force). After every code-editing batch, backend-only included, and after any merge or pull.
2. **Print the named URL** read from the worktree `.env` per the repo skill.
3. **SQL via `/dev:sql`.** Never edit, branch, or commit SQL in `/Users/derek/eBacon/SQL` from a Viper worktree; `/dev:sql` makes a SQL worktree named after this branch, commits, pushes, and runs the MassScriptBuilder in both modes (regular in the SQL worktree for `_template.js`; targeted-branch from the SQL repo root for the gitignored `__template.js` plus numbered `.sql` scripts). The batch isn't review-ready until that has run; surface the script path.
4. **Verify** with `/verify` (drive the change through the app). Skip only when the diff has no runtime surface. A real failure gets fixed or reported before step 6.
5. **Summarize:** URL, SQL script path, what changed. Short.
6. **Blast-radius gate:**

   | Class | Viper signals | Policy |
   |---|---|---|
   | TINY / SMALL | copy, styling, config, localized single-feature logic | after `/verify` passes, offer `/dev:wrapup` |
   | MEDIUM | multi-file logic, shared components, new endpoints/controllers | `/verify` + explicit risk summary before offering wrapup |
   | LARGE | SQL/schema, auth/session/permissions, payroll or money calc, migrations, broadly-imported core modules | HARD STOP. No PR offer. Present risks, wait for an explicit "go" |

   No auto-merge at any tier; I merge on GitHub.
7. **Offer (numbered):** 1. `/dev:wrapup` (commit/push/PR/standup), 2. stop for manual review. LARGE never advances past 6 without the go.

## Upload stub corpus

For the repo skill's "Testing uploaded files": `/Users/derek/eBacon/exampleFiles/` holds one `example.<ext>` per type plus `rejected-example.exe` / `rejected-example.js`. `example.eml` is whitelisted by neither stack, so it is a third rejection case.

```bash
cp "/Users/derek/eBacon/exampleFiles/example.${P##*.}" "public/$P"
curl -b "PHPSESSID=<id>" -F "userfile[]=@/Users/derek/eBacon/exampleFiles/example.pdf" \
  "http://$VIPER_APP_HOST:$DC_APP_PORT/<controller>/<method>"
```

CI3 multi-upload reads `$_FILES["userfile"]` (array form); CI4 `UploadLibrary::upload()` takes the endpoint's own field name. Round-trip a success by reading back the new `t_document` row and confirming the bytes at its `filePath`. Plant dummies in the worktree, not in main's `public/uploaded/`.
