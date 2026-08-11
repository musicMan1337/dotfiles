# WORKSTATION mode

Audit THIS machine's agent-to-secret surface. Scope every discovery to named dirs (scan-guard will kill a home-rooted sweep). Delegate the inventory to `reader` subagents, one per dir group, results as terse path+mode lists (never contents).

## Inventory (E1): check existence + mode, not contents

Named locations, each a separate scoped check:
- `~/.aws/`, `~/.ssh/`, `~/.kube/config`, `~/.docker/config.json`
- `~/.npmrc` (look for `_authToken=`), `~/.git-credentials`, `~/.netrc`, `~/.pgpass`
- `~/.vault-token`, `~/.snout`, `~/.config/` app credential dirs you can name
- project `.env*` files only in repos the user names (do not walk all of `~`)

Flag world/group-readable modes. Report as a table: path, exists, mode, likely-secret (yes/candidate).

## E2 brokers

- Discovery files present (`~/.snout`, `~/.vault-token`) and what they grant.
- Loopback listeners: `lsof -nP -iTCP -sTCP:LISTEN` (scoped, not a full scan) and map suspicious ports to the owning app.
- For each broker, read its auth model in its repo (per-caller auth? user-only? any-scope path?). eBacon topology: `~/eBacon/attacksurface.md`.
- Output RECOMMENDATIONS only (approval prompt + audit + caller-identity-as-context + egress-deny the port). Do not claim to configure a mask for this.

## E3 process env

- Is the interactive/agent shell launched with real secrets in env? Are dev servers started with real vs fake values?
- Recommend fake-env for anything the agent runs; real env only for narrowly-scoped commands.

## E4 transcript

- Is `~/.claude/projects` writable by processes the agent spawns (it is, same UID)? Note the forged-turn integrity gap and the replay-reloads-unmasked confidentiality gap.
- Recommend: keep secrets out of tool output (deny/isolation); consider a write-guard/monitor on the transcript dir; rotation as recovery.

## CC config (E7/E8)

- Enumerate wired hooks (`~/.claude/settings.json`) and their tool matchers; build the coverage matrix.
- `settings.local.json` present? What is in `permissions.deny`?
- `core.hooksPath` set to the global hooks?

## Configure (fail-closed first)

1. **deny (E1/E8):** append enumerated secret paths to `permissions.deny` in the TRACKED `~/dotfiles/claude/settings.json` (the `/update-config` path), date-stamped. Include the Bash-bypass forms where the deny grammar allows, or note deny is Read-only.
2. **git hooks (E6):** confirm `core.hooksPath` points at the global hooks; if not, that is a one-line `git config --global`.
3. **seatbelt masks (E7), optional:** emit `assets/mask-hook.sh` wired for `Read|Bash|Grep|NotebookRead` (+ `mcp__*` if the user has secret-returning MCP servers). Every emitted hook carries the fail-open caveat comment. Report uncovered channels.
4. **E2/E3/E4:** written recommendations, labeled as design changes not made here.

## Verify

Run the deny red-green and the masking fail-open probe from `controls.md` in a throwaway dir with a fake token. Show the fail-open result so the seatbelt framing is concrete.
