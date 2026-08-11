# Threat model E1-E8

For each: what it is, how to detect it (scoped, scan-guard-safe), the control that applies, and the residual risk after that control. Detection commands name specific dirs; never root a sweep at `~` or `/`.

## E1 Plaintext secret files readable by the agent's shell

Files a shell running as the user can `cat`. Common: `.env`, `.env.*`, `*.pem`, `id_rsa`/`id_ed25519`, `~/.aws/credentials`, `~/.ssh/*`, `~/.kube/config`, `.npmrc` (`_authToken=`), `.git-credentials`, `~/.vault-token`, `~/.snout`, `~/.docker/config.json`, `.pgpass`, `.netrc`.

- **Detect:** per-dir `ls`/`Glob`, not a home sweep. Check existence + mode bits; never read contents.
- **Control:** `permissions.deny` Read of each (fail-closed) AND, for the Bash bypass, deny/monitor `cat`/`less`/`sops -d` of them if the deny format allows; otherwise isolation.
- **Residual:** Read-deny does not stop `Bash cat`. A file that must exist in plaintext for a local tool still exists; deny only stops the agent's Read tool, not the tool that legitimately needs it.

## E2 Localhost secret brokers (confused deputy)

A loopback service that authenticates the USER and hands secrets to any caller: a Vault desktop proxy, an agent sidecar, `~/.snout`'s proxy. The auth is ambient (the user's session), so any local process, including the agent's shell, inherits it.

- **Detect:** discovery files (`~/.snout`, `~/.vault-token`), listeners on loopback (`lsof -nP -iTCP -sTCP:LISTEN` scoped), the broker's own auth model in its repo.
- **Control:** NOT a mask. Human-in-the-loop approval out of band from the requesting process (a tray prompt), caller identity as CONTEXT + audit only (ancestry is bypassable via setsid/double-fork; interpreters are shared with legit use), and killing any "any-scope" path fallthrough. Egress-deny the broker port raises cost.
- **Residual:** approval fatigue degrades to blanket-allow without consumer pre-registration. Caller identity never proves intent.

## E3 Process-env secrets

Secrets in the agent process's environment, inherited by every child it spawns. A `printenv`, a framework that holds `$STRIPE_KEY`, a `.env` already sourced into the shell.

- **Detect:** does the session's launch environment carry real secrets? Are dev servers started with real vs fake env?
- **Control:** isolation, real secrets never enter the interactive/agent environment; local/dev uses fakes. No CC hook helps here (env is read by child processes, not a CC tool).
- **Residual:** anything the agent legitimately must run that needs the real value reintroduces exposure. Scope which commands get which env.

## E4 Transcript persistence + integrity

Two problems in one file (`~/.claude/projects/**/*.jsonl`). Confidentiality: a secret in tool output persists and reloads on `--resume`/compaction; masking protects the first read only if the hook succeeds (see `controls.md` F2/F3), and replay re-runs no hooks. Integrity: a child process can APPEND forged turns (fabricated user/assistant/tool messages) that are indistinguishable from real history, the strongest form of prompt injection.

- **Detect:** does any local process write under `~/.claude/projects`? Is that dir writable by tools the agent runs?
- **Control:** keep secrets out of tool output in the first place (deny/isolation); guard/monitor writes to the transcript dir; treat rotation as the recovery path once a value is recorded.
- **Residual:** no supported CC primitive verifies transcript integrity; forged-turn detection is a design gap. Recommend, do not claim to close.

## E5 Outbound exfil

The agent can send a secret it obtained: `curl`/`fetch`, an MCP tool with network reach, a webhook, a commit+push to a public remote.

- **Detect:** what egress is reachable from the agent's Bash? Is there a Bash egress guard (`bash-egress-guard.sh`)? Which MCP servers can make outbound calls?
- **Control:** egress denylist for known sinks (best-effort), least-privilege MCP, and the upstream fix, do not let the agent hold the secret (E1-E3).
- **Residual:** egress denylists are leaky; a novel sink or an MCP tool walks around them. Containment beats interception.

## E6 Commit-time leakage

Secret material, AI self-attribution (`Co-Authored-By: Claude`, "Generated with", robot emoji), or the em-dash char reaching a commit or message. Messages never pass through Write/Edit; they go through `git commit`, so only a git hook sees them.

- **Detect:** `core.hooksPath` set? Do the global hooks exist? Does the repo override with husky/lefthook?
- **Control:** the global `~/dotfiles/git/hooks/` (`pre-commit` em-dash + staged secret scan, `commit-msg` attribution), writer-agnostic. Extend `pre-commit` with `assets/secret-scan-precommit.sh`.
- **Residual:** husky repos bypass the global hooks (they get their own). A committed secret in HISTORY needs rotation + history rewrite, not a hook.

## E7 Hook-coverage gaps

A guard/mask hook that matches some tool channels and not others. `Read|Bash`-only masking leaves `mcp__*`, `NotebookRead`, and (for masking) transcript replay uncovered. A PreToolUse guard on `Write|Edit` misses Bash redirects and heredocs.

- **Detect:** enumerate wired hooks and their matchers; build the `controls.md` coverage matrix.
- **Control:** match ALL relevant channels or explicitly report the gaps. There is no "cover everything" matcher; name what you left open.
- **Residual:** every added channel is more surface for the hook itself to error on (fail-open). Coverage and reliability trade off.

## E8 CC permission-config integrity

`settings.local.json` is untracked (no diff, no review); deny rules can be walked around (Read-deny vs Bash, symlinks into a denied dir from an allowed path).

- **Detect:** is `settings.local.json` present? What is in `permissions.deny` vs `permissions.allow`? Any allow rule that overrides a deny?
- **Control:** write policy to the TRACKED settings only (`sensitive-write-guard` already blocks editing `settings.local.json`); prefer deny over allow for secret paths; verify deny survives the Bash bypass.
- **Residual:** a determined local process edits its own config unless a hook blocks it. The `sensitive-write-guard` covers the known untracked surfaces; new ones need adding.
