---
name: obsidian:skill-tracker
model: haiku
description: Track skill usage stats and prune unused skills via Obsidian note. Triggers on: track skills, skill usage, prune skills
allowed-tools: Bash(source ~/.zprofile && obsidian *), Bash(node *), Bash(ls *), Bash(readlink *), Bash(rm *), Bash(unlink *), Read, Edit, Glob
---

# Skill Tracker

Track which Claude Code skills are actually used so unused ones can be pruned. Unused skills waste context space — their descriptions are always loaded.

## Input

**Request:** $ARGUMENTS

- No args → full run: extract usage, update table, scan for unused, offer pruning
- "update" / "refresh" → just update the table, skip pruning prompt
- "prune" / "clean" → skip to scanning for unused skills and pruning

## Step 1 — Check last run date

Read the existing tracker note:
```bash
source ~/.zprofile && obsidian read path="skill-tracker.md"
```

If the file exists, parse the first line for the last-updated date. Format: `> Last updated: YYYY-MM-DD`

If no file exists, this is the first run — no `--since` flag needed.

## Step 2 — Run extraction script

```bash
node ~/.claude/commands/obsidian/skill-tracker/lib/extract-usage.js [--since YYYY-MM-DD]
```

Pass `--since` with the last-updated date if available. Otherwise omit it to scan full history.

The script outputs JSON mapping skill names to `{ count, lastUsed, firstUsed, projects, sessions }`.

## Step 2b — Verify script filter lists

The extraction script at `~/.claude/commands/obsidian/skill-tracker/lib/extract-usage.js` has three lists that need maintenance as skills are added/renamed/removed:

1. **`BUILTIN_COMMANDS`** — built-in CLI commands to exclude (e.g., `help`, `clear`, `usage`)
2. **`NAMESPACE_ONLY`** — bare namespace words to exclude (e.g., `factory`, `git`) — these are accidental invocations without a subcommand
3. **`RENAMES`** — maps old skill names to current canonical names (e.g., `git-commit` → `git:commit`)

**After running the script, scan its output for anomalies before proceeding:**

- **Unrecognized names** that look like builtins or typos (short, no colon, not a known skill) → add to `BUILTIN_COMMANDS`
- **Bare namespace words** without subcommands → add to `NAMESPACE_ONLY`
- **Old-name / new-name pairs** both appearing (same skill, different eras) → add to `RENAMES`
- **File paths or garbage** leaking through → tighten the path/length filters

Cross-reference against installed skills (`~/.claude/commands/`) — if a name in the output doesn't match any installed skill and isn't in `RENAMES`, it's either a deleted skill (fine, historical data) or noise (needs filtering).

**If any list needs updating:** edit the script, then re-run it before continuing. This is expected maintenance — new skills get added regularly.

## Step 3 — Merge with existing table

If the tracker note already exists, parse its markdown table. For each skill in the new extraction:

- **Skill already in table:** Add new `count` to existing total, update `lastUsed` if newer, merge projects list
- **Skill not in table:** Add new row

**Table format:**

```markdown
> Last updated: YYYY-MM-DD

| Skill | Total Uses | Sessions | Last Used | First Used | Projects |
|-------|-----------|----------|-----------|------------|----------|
| git:commit | 22 | 15 | 2026-04-14 | 2026-03-05 | dotfiles, Viper, Core |
| obsidian:standup | 25 | 18 | 2026-04-14 | 2026-03-07 | dotfiles, Viper |
```

Sort by **Total Uses descending** — most-used skills at top.

**Handle renamed skills:** Some skills were renamed over time (e.g., `git-commit` → `git:commit`, `obsidian-standup` → `obsidian:standup`). When both old and new names appear, merge them under the current name. Known renames:
- `git-commit` → `git:commit`
- `git-pr` → `git:pr`
- `standup-notes` / `obsidian-standup` → `obsidian:standup`
- `obsidian-followup` → `obsidian:followup`
- `obsidian-investigate` → `obsidian:investigate`
- `obsidian-briefing` → `obsidian:briefing`
- `obsidian-pr-notes` → `obsidian:pr-notes`
- `research-orderings` → `research:orderings`
- `spec-developer` → `spec:developer`
- `spec-implement` → `spec:implement`
- `spec-audit` → `spec:audit`
- `spec-advisor` → `spec:advisor`
- `mcp-restart` → `mcp:restart`

## Step 4 — Write updated table to Obsidian

```bash
source ~/.zprofile && obsidian create path="skill-tracker.md" content="..." overwrite
```

Update the `Last updated` line to today's date.

## Step 5 — Scan for unused / stale skills

List all installed skills:
```bash
ls ~/.claude/commands/
```

For namespace directories, list their contents too:
```bash
ls ~/.claude/commands/git/
ls ~/.claude/commands/obsidian/
# etc.
```

Build a complete list of installed skill names. Cross-reference against the usage table.

Categorize:
1. **Never used** — installed but zero entries in the table
2. **Stale (>2 weeks)** — last used more than 14 days ago
3. **Low usage** — used fewer than 3 times total

Present a numbered list, **least-used first** (never-used, then stale by oldest-last-used, then low-usage):

```
Skills that may not be earning their context space:

Never used:
  1. allow-node (installed, 0 uses)
  2. toggle-costs (installed, 0 uses)

Not used in 2+ weeks:
  3. hetzner:setup (1 use, last: 2026-03-11)
  4. gsd:cleanup (1 use, last: 2026-03-11)

Low usage (<3 total):
  5. ccusage (1 use, last: 2026-03-27)
  6. linting:setup (1 use, last: 2026-04-06)

Delete any? (e.g., "1-4" or "2, 5, 6" or "none")
```

## Step 6 — Delete selected skills

If the user selects skills to delete, for each one:

1. **Resolve the file path** — determine if it's a single `.md` file or a directory:
```bash
ls -la ~/.claude/commands/<skill-path>
```

2. **Check if it's a symlink:**
```bash
readlink ~/.claude/commands/<skill-path>
```

3. **Delete:**
   - If symlink: `unlink ~/.claude/commands/<skill-path>` (removes symlink only)
   - Then delete the source in dotfiles: `rm ~/.claude/commands/<source-path>` or `rm -rf` for directories

**Warning:** Before deleting, confirm the list one more time. Show exact paths that will be removed. This is destructive and irreversible.

**Never delete the `dev/` directory** — it's a real local-only directory, not symlinked from dotfiles.

After deletion, show what was removed and remind the user to commit the dotfiles change.

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Renamed skills inflate counts if not merged.** The rename map in Step 3 is critical — without it, `git-commit` (89 uses) and `git:commit` (22 uses) look like two different skills. Update the map when skills are renamed.
- **Plugin skills vs file skills.** Some skills come from plugins (e.g., `code-review`) — they show in the installed list via `settings.json` plugins, not as files in `commands/`. These can't be "deleted" the same way — they need to be disabled in settings instead. Flag these differently in the prune list.
- **dev/ is sacred.** Never offer to delete anything in `~/.claude/commands/dev/` — it's a real directory with local-only skills, not symlinked from dotfiles.
- **History only tracks invocations, not implicit triggers.** If a skill auto-triggers from conversation context (description matching), that invocation may not appear as `/skill-name` in history. Usage counts are a lower bound.
- **Don't delete skills the user just created.** If a skill was created today or in the current session, it'll show as "never used" — that's expected. Use `firstUsed` / file creation date as a signal.
- **Script filter lists go stale.** Every time a new skill is added or renamed, the script's `BUILTIN_COMMANDS`, `NAMESPACE_ONLY`, and `RENAMES` maps may need updating. Always verify output before writing to the note. This is normal maintenance, not a bug.
