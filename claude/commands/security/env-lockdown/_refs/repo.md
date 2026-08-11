# REPO mode

Scoped to the current repo. Composes with `setup:package-lockdown` (supply chain); this covers what a running agent can read/leak from THIS repo. One repo at a time (scan-guard).

## Detect (scoped to the repo root + its .claude/)

- **.gitignore coverage:** are `.env*`, `*.pem`, `id_*`, `*.key`, `secrets*.json` ignored? An unignored `.env` is one `git add -A` from a committed secret.
- **Already-committed secrets:** delegate a scoped `git log -p -S<pattern>` or `git grep` over tracked files (NOT a working-tree sweep of node_modules). Check history, since removing from HEAD leaves it in history.
- **Repo `.claude/`:** `settings.json`/`settings.local.json` permissions, any repo-local hooks, any `.mcp.json` servers that return secrets.
- **git hooks:** does the repo set its own `core.hooksPath` (husky/lefthook) that bypasses the global hooks? Are there native `.git/hooks/*`?
- **.env handling:** is there a `.env.example` with placeholder values, and is the real `.env` gitignored? Does the app read secrets from env or from a broker?

## Grade

Map E1 (repo secret files), E6 (commit leakage), E7/E8 (repo CC config) to controls. E2/E3/E4 are usually WORKSTATION concerns but note if the repo ships a broker or a dev-server that bakes real env.

## Configure (fail-closed first)

1. **.gitignore (E6):** add missing secret-file globs. Cheap, fail-closed against accidental `git add`.
2. **repo permissions.deny (E1/E8):** if the repo has real secret files that must exist locally, add Read-deny for them to the repo `.claude/settings.json` (tracked, shared via the repo), date-stamped. Never `settings.local.json`.
3. **git hooks (E6):** if the repo uses husky/lefthook (bypasses global hooks), add the em-dash + attribution + staged-secret checks INTO the repo's own hook config so coverage is not lost. Otherwise rely on the global hooks; optionally add `assets/secret-scan-precommit.sh` chained from the repo hook.
4. **seatbelt masks (E7):** rarely needed at repo scope; if the repo's MCP servers return secrets, a matched `mcp__*` mask is defense-in-depth. Fail-open caveat applies.

## Verify

- Red-green the `.gitignore`: `git check-ignore .env` returns the path (green); a `git add --dry-run .env` shows it ignored.
- If deny rules were added, run the deny red-green from `controls.md` against a repo path.
- If a staged-secret pre-commit check was added, red-green it: stage a file with a fake `AKIA…`-shaped token, confirm the commit is blocked, then a clean file passes.
