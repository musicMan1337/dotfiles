---
name: security:env-lockdown
model: opus
description: Assess and harden a dev environment's exposure of secrets to agent-driven tooling (a coding agent with shell access). Fail-closed-first, package-lockdown's sibling for secret exposure. Two modes, WORKSTATION (this machine's agent-to-secret surface) and REPO (the current repo's CC config, .env handling, git hooks). Triggers on, env lockdown, environment lockdown, harden my environment, can an agent read my secrets, lock down secrets, secret exposure, agent secret surface, secret-safe this repo, mask secrets from claude, permissions deny secrets, transcript leak, confused deputy secrets, env-lockdown, /security:env-lockdown.
allowed-tools: Agent, Bash, Read, Write, Edit, Glob, Grep, Skill
---

Goal: reduce what a coding agent with shell access can read, exfil, or persist, across 8 exposure vectors, and do it fail-closed-first. This is the secret-exposure sibling of `setup:package-lockdown` (that hardens the third-party supply chain; this hardens what a running agent can reach). They compose, do not overlap.

## Threat model (E1-E8)

Detail + detection commands + control mapping in `_refs/threat-model.md`. Load it in Phase 1.

- **E1 Plaintext secret files** readable by the agent's shell: `.env*`, `*.pem`, `id_*`, `~/.aws/credentials`, `~/.ssh/*`, kubeconfig, `.npmrc` `_authToken`, `.git-credentials`, `~/.vault-token`, `~/.snout`.
- **E2 Localhost secret brokers** that authenticate the USER, not the CALLER (confused deputy): a Vault desktop proxy / agent sidecar with no per-caller auth. Any local process inherits the user's authority.
- **E3 Process-env secrets** inherited by child processes the agent spawns (`printenv`, a leaked `$STRIPE_KEY`).
- **E4 Transcript persistence + integrity**: secrets landing in `~/.claude/projects/**/*.jsonl`, reloaded on `--resume` and compaction; and a child process forging turns by appending to that file.
- **E5 Outbound exfil**: the agent can POST a secret it read (curl, fetch, an MCP tool, a webhook).
- **E6 Commit-time leakage**: secret material, AI self-attribution, or the em-dash char reaching a commit or message.
- **E7 Hook-coverage gaps**: a guard/mask hook matching some tool channels but not others (Bash heredocs, MCP output, NotebookEdit) leaves the uncovered channels wide open.
- **E8 CC permission-config integrity**: untracked `settings.local.json`, deny rules that a Bash redirect or a symlink walks around.

## Source of truth

- The measured facts about Claude Code's own controls live in `_refs/controls.md`. They were verified by isolated headless runs against **Claude Code 2.1.227 on 2026-08-11**, not inferred. Re-verify on a CC minor-version bump (the hook-output schema can change).
- The existing global git hooks at `~/dotfiles/git/hooks/` (`pre-commit`, `commit-msg`, `_lib.sh`) are the reference implementation for E6. Detect and reuse them; do not reinvent.
- eBacon's Vault/Snout topology (E2) is described in `~/eBacon/attacksurface.md`. Read it before proposing broker changes.

## Skill invariants (non-negotiable)

These are the difference between hardening and security theater. Each is measured; cite `_refs/controls.md` when a user pushes back.

1. **`permissions.deny` (Read of enumerated paths) is the only fail-CLOSED CC control.** Prefer it for every secret path you can name. On any error it denies. Nothing else here has that property.

2. **`updatedToolOutput` masking is FAIL-OPEN.** Verified: a PostToolUse mask hook that exits non-zero OR exceeds its timeout delivers the RAW tool output to the model AND writes it to the transcript. So a mask hook is a labeled SEATBELT, never a boundary. Every mask hook this skill emits carries that caveat in its own header comment. Do not present masking as protection a caller cannot defeat, because a caller who can force an error or a timeout (an oversized file, a payload that breaks the hook) defeats it.

3. **Masking still earns its place as defense-in-depth.** Verified: on hook SUCCESS the raw value never reaches the transcript, only the masked value persists. So layer it, just never rely on it alone.

4. **Environment isolation is the only control that survives code execution as the user.** Real secrets must not live where the agent's shell can reach them; local/dev gets fake values, real Vault material lives where the agent cannot run code. Pattern masking recognizes shapes, not secrecy, so it cannot catch arbitrary-shaped secrets (DB passwords, HMAC peppers). Never sell masking as a substitute for the secret not being reachable.

5. **Known-VALUE masking beats pattern masking, and is still a seatbelt.** Loading the same values the app loads and exact-string-redacting them catches secrets no regex would. It is defeated by any encoding (base64/json/split across lines) and by derived tokens. Annotate as such.

6. **Global git hooks (`core.hooksPath`) are the writer-agnostic E6 catch.** They see commits from Bash heredocs and other agents/editors that tool-boundary hooks miss. Reuse the existing ones; optionally extend `pre-commit` with staged-diff secret-pattern scanning (`assets/secret-scan-precommit.sh`).

## Operational constraints

- **Delegate discovery sweeps to `reader` (Haiku) subagents, each scoped to a named directory or glob set.** Respect the scan limits in `~/dotfiles/CLAUDE.md`: no home-rooted or unfiltered scans, one repo at a time, prefer one aggregate pass over many sweepers. The `scan-guard.sh` hook hard-denies the bad forms; do not fight it, scope the search.
- **Never write a real secret value into any config, hook, report, or scratch file.** Known-value mask hooks read values at runtime from the same source the app uses; they never bake a value into a tracked file. If you cannot mask without embedding a value, stop and say so.
- **The skill writes configs + reports and prints commands; it does not run installs or exfil.** No step of this skill should read a secret and send it anywhere.
- **Refuse on uncertainty.** If you cannot confirm a path holds a secret, flag it as a candidate; do not blanket-`deny` a path whose denial would break the user's normal workflow. A deny that breaks `npm install` gets removed and the lesson is lost.

## Phase 1: Detect

Spawn one `reader` subagent per scoped target (workstation: the enumerated home-dir credential locations + `~/.claude/settings*.json`; repo: the repo root + its `.claude/`). Each returns, under 300 words:

- Which E1 files exist (path + mode bits; never contents).
- E8: is `~/.claude/settings.local.json` present and untracked? What does `permissions.deny` currently contain?
- E6: is `core.hooksPath` set? Do `~/dotfiles/git/hooks/{pre-commit,commit-msg}` exist? Does this repo set its own `core.hooksPath` (husky/lefthook) that would bypass the global hooks?
- E7: which PostToolUse/PreToolUse hooks are wired, and which tool matchers do they cover?
- Repo mode also: `.gitignore` coverage of `.env*`/`*.pem`, any secret already committed (delegate to a scoped `git log -p` grep, not a working-tree scan).

## Phase 2: Classify mode

`WORKSTATION` or `REPO` (or both, run REPO after WORKSTATION). Announce in one sentence. Load `_refs/workstation.md` or `_refs/repo.md` accordingly. E2/E3/E4 are WORKSTATION concerns; E6/E8 are strongest in REPO.

## Phase 3: Grade exposure

For each E-vector present, map it to the control that applies and its current state, using the hierarchy in `_refs/controls.md`: **deny (fail-closed) > isolation > known-value mask > pattern mask > detection-only**. Grade each vector unprotected / seatbelt-only / bounded. Fail-closed-first means: if a vector can be closed with `permissions.deny` or isolation, a mask hook does not count as "handled."

## Phase 4: Configure

Verify each target before writing (a path exists and plausibly holds a secret; a hook file is where you think). Then:

- **E1/E8:** append enumerated paths to `permissions.deny` (Read + the Bash `cat`/`less` equivalents where the deny format supports it). Write to the TRACKED settings, never `settings.local.json`. Date-stamp the block.
- **E6:** if the global hooks are absent, point the user at `~/dotfiles/git/hooks/`; if present, optionally add `assets/secret-scan-precommit.sh` as an extra staged-diff check. Never auto-enable a repo-level `core.hooksPath` that would shadow husky.
- **E7:** emit labeled seatbelt mask hooks from `assets/mask-hook.sh` for the tool channels the user wants belt-and-suspenders on, matching ALL relevant tools (`Read|Bash|Grep|NotebookRead` and the MCP variant via `updatedMCPToolOutput`). Report every channel you did NOT cover.
- **E2/E3/E4:** these are design changes, not files. Produce written RECOMMENDATIONS (caller-identity + audit for brokers, fake-env for local/dev, transcript-write guarding). Do not pretend a hook fixes them.

## Phase 5: Report

1. **Mode + exposure table:** one row per E-vector, its grade (unprotected / seatbelt / bounded), and the control now in place.
2. **What changed:** files touched, each tagged with the vector and the layer (deny / git-hook / seatbelt-mask).
3. **Coverage matrix (E7):** tool channels x covered?, naming every bypass (Bash still `cat`s a non-denied file; MCP output only if matched; transcript replay re-runs no hooks).
4. **Residual risks:** E2/E3/E4 recommendations, plainly labeled as needing a design change you did not make.
5. **Commands for the user, numbered.** Verification first: the deny red-green and the masking fail-open probe from `_refs/controls.md`.

## Phase 6: Verify + iterate

Red-green every control you claim closed a vector (this is `~/dotfiles/CLAUDE.md`'s "nothing is done until exercised"):

- **deny:** attempt a Read of a denied path in a throwaway `claude -p --settings` run; confirm it is refused.
- **mask seatbelt:** plant a fake token, confirm masking on success, then break the hook (`exit 1`) and confirm the fail-open behavior so the user sees the seatbelt is a seatbelt. Recipe in `_refs/controls.md`.

When the user reports a bypass this skill missed, add a Gotcha and, if it is a new vector, a row to `_refs/threat-model.md`.

## Gotchas

- **The fail-open result is the whole point of the skill.** If you catch yourself telling the user a mask hook "prevents" a leak, stop. It prevents it only while the hook runs cleanly. Say "seatbelt," show the probe.
- **`permissions.deny` on Read does not stop `Bash`.** A denied `Read(.env)` is walked around by `cat .env`. Either also deny the Bash forms or accept deny is Read-only. This is the top false-sense-of-security failure.
- **`updatedToolOutput` is shape-validated per tool.** Mutate the RECEIVED `tool_response` (string-replace inside it); never synthesize a shape. A shape mismatch makes the hook error, which is fail-open. Verified failure string: "PostToolUse hook returned updatedToolOutput that does not match <tool>'s output shape."
- **Transcript replay runs no PostToolUse hooks.** A secret already in a `.jsonl` reloads on `--resume`/compaction unmasked. Masking protects the first read, not history. Rotation, not redaction, is the recovery path once a value is in a transcript.
- **MCP tool output needs the MCP matcher.** `updatedToolOutput` covers all tools only if the matcher covers them; a SQL/MCP secret read bypasses a `Read|Bash`-only mask. Cover `mcp__.*` explicitly or say you did not.
- **Blank masks make the model hunt.** Redact to a loud placeholder (`[REDACTED:AWS_KEY]`), not empty string, or the model concludes the file is empty and goes looking for the value elsewhere.
- **Silent mutation lies to the model.** A mask changes what the model "knows it wrote/read." Prefer `permissionDecision: deny` (the model self-corrects) for cases where the model should not have the value at all; reserve masking for values it may see redacted.
- **`settings.local.json` is untracked.** Writing deny rules there produces no git diff and no review. Always write to the tracked settings; the `sensitive-write-guard` hook already blocks edits to `settings.local.json` for this reason.
- **Confused-deputy brokers cannot be fixed with a mask.** A localhost secret proxy that authenticates the user (E2) hands secrets to any local process. Caller-identity checks are bypassable (setsid/double-fork) and cannot distinguish an agent from a legit interpreter; the real fix is a human-in-the-loop approval out of band from the requesting process, plus audit. Recommend, do not pretend to configure.
- **Do not oversell known-value masking.** It is defeated by `base64`, `json_encode`, urlencode, splitting the value across lines, and by any token derived from the secret. Seatbelt.
- **Scan-guard will kill open-ended sweeps.** "Find all secrets on the machine" rooted at `~` trips CryptoGuard and gets the session killed. Enumerate specific dirs; one repo at a time.
- **Do not write example secrets into the repo.** Test tokens (`SNOUTTEST_...`) belong in a scratch dir, never in a tracked asset or fixture; and they still persist in whatever transcript recorded the test.

## References

| File | Load when |
|---|---|
| `_refs/threat-model.md` | Phase 1. E1-E8 detail, detection commands, control mapping, residual risk. |
| `_refs/controls.md` | Phases 3-6. The measured CC-control facts, the fail-closed>isolation>mask hierarchy, the deny red-green + masking fail-open probe recipes, the coverage matrix template. |
| `_refs/workstation.md` | WORKSTATION mode. The home-dir credential inventory + broker/env/transcript checks. |
| `_refs/repo.md` | REPO mode. The per-repo CC-config, .env/.gitignore, git-hook checks. |
| `assets/mask-hook.sh` | Emitting a labeled seatbelt PostToolUse mask hook (known-value + pattern). |
| `assets/secret-scan-precommit.sh` | Adding staged-diff secret-pattern scanning to `pre-commit`. |

## Growing this skill

Every bypass a user finds becomes a Gotcha; every new exposure channel becomes an `_refs/threat-model.md` row. When a CC release changes hook behavior, re-run the probes in `_refs/controls.md` and update the measured facts with the new version + date. The harness should shrink as CC ships fail-closed primitives; if CC adds a path-scoped Write/Bash deny that covers redirects, retire the corresponding scaffold here.
