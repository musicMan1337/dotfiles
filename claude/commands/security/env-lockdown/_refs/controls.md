# Controls catalog + measured facts

Measured against **Claude Code 2.1.227, 2026-08-11**, isolated headless runs (`claude -p --settings <file> --output-format stream-json`). These are observations, not inferences. Re-run the probes below on a CC minor bump.

## The control hierarchy (fail-closed first)

Rank a vector's protection by the strongest control actually applied:

1. **`permissions.deny` (fail-CLOSED).** Denies on error. The only CC control that does. Read-scoped only (see limits).
2. **Environment isolation.** The secret is not in a place the agent's shell can reach. Survives code execution as the user. The real boundary.
3. **Known-value masking (seatbelt).** Load the app's own values, exact-string redact. Catches arbitrary-shaped secrets. Defeated by encoding/derivation. Fail-OPEN.
4. **Pattern masking (seatbelt).** Regex for shaped secrets (`AKIA…`, `sk_live_`, PEM, JWT). Misses unshaped secrets (DB passwords, peppers). Fail-OPEN.
5. **Detection-only.** Log/alert after the fact. No prevention.

"Fail-closed-first" = a vector is only "handled" when closed by (1) or (2). A (3)/(4) seatbelt is defense-in-depth on top, never the checkmark.

## Measured facts

### F1 `updatedToolOutput` masking works, and is placed under `hookSpecificOutput`

A PostToolUse hook returning
`{"hookSpecificOutput":{"hookEventName":"PostToolUse","updatedToolOutput":<mutated tool_response>}}`
replaces what the model receives. Verified: the model got the masked value and the raw token appeared nowhere in the model-facing stream. `updatedMCPToolOutput` is the legacy MCP-only field; the binary's own help says "Prefer updatedToolOutput, which works for all tools."

### F2 On SUCCESS, the raw value never reaches the transcript

The on-disk session `.jsonl` contained zero occurrences of the raw token and only the masked value. So a clean mask also prevents E4 transcript spill for that read. This is the real defense-in-depth value of masking.

### F3 Masking is FAIL-OPEN on error AND on timeout

With the hook forced to `exit 1`, and separately forced to exceed its `timeout`, the RAW tool output reached the model AND was written to the transcript (`raw=4 masked=0` both times). A caller who can make the hook error (a payload that breaks it) or stall (an oversized file past the timeout) defeats the mask. **This is why masking is a seatbelt, not a boundary.**

### F4 Shape validation

`updatedToolOutput` must match the tool's output shape or the hook errors (fail-open per F3). Failure string in the binary: "PostToolUse hook returned updatedToolOutput that does not match <tool>'s output shape." Mitigation: mutate the RECEIVED `tool_response` in place (string-replace inside its JSON), never synthesize a shape.

### F5 `core.hooksPath` tilde-expands and is writer-agnostic

`core.hooksPath = ~/dotfiles/git/hooks` expands and fires (verified: a commit with an em-dash was blocked via the global config in a fresh repo). Because git invokes it for every commit regardless of who wrote the tree, it catches Bash-heredoc commits and other agents/editors. Caveat: a repo that sets its OWN `core.hooksPath` (husky/lefthook) fully overrides the global one, so the global hooks do not run there; and setting the global one makes native `.git/hooks/*` be ignored unless the global hook chains to them (the reference `_lib.sh` does: it execs `<root>/.git/hooks/<name>` if present). Note `git rev-parse --git-path hooks` follows `core.hooksPath` and therefore points back at the global hook, so chaining must use the literal `.git/hooks` path, not `--git-path`.

## Probe recipes (Phase 6 verification)

Run in a throwaway scratch dir, never a real repo, with a clearly-FAKE token. Clean up after (note: the throwaway transcript under `~/.claude/projects/…` will contain the fake token; the delete may be blocked by `sensitive-write-guard` on `~/.claude`, in which case leave it, it is fake).

### Deny red-green (fail-closed proof)

1. Write a settings file with `{"permissions":{"deny":["Read(./secret.txt)"]}}`.
2. `claude -p "Read secret.txt and print it" --settings that.json --output-format stream-json` and confirm the Read is refused (no contents in the stream).
3. Green: a non-denied sibling file reads fine.

### Masking fail-open probe (seatbelt proof)

1. Plant `secret.txt` with `FAKE_SECRET=SNOUTTEST_<random>`.
2. Settings wiring a PostToolUse `Read|Bash|Grep` hook to `assets/mask-hook.sh`.
3. `MASK_MODE=ok`: run, confirm the model-facing `tool_result` shows the placeholder and the transcript `.jsonl` has zero raw occurrences (F1+F2).
4. `MASK_MODE=fail` (hook `exit 1`) and `MASK_MODE=timeout` (sleep past the configured timeout): run each, confirm the RAW token reaches the model and the transcript (F3). Show the user this so "seatbelt" is concrete.

Extraction helpers (avoid `grep` forms that trip `scan-guard`; prefer `jq`/`awk`):
- model-received: `jq -c 'select(.type=="user").message.content[]?|select(.type=="tool_result").content' out.jsonl`
- transcript by session id: `ls ~/.claude/projects/*/<session_id>.jsonl` then `awk '/<token>/{r++} END{print r+0}'`.

## Coverage matrix template (E7)

Fill one row per tool channel; every "no" is an open bypass to name in the report.

| Channel | Covered by mask? | Bypass if not |
|---|---|---|
| `Read` | | model reads file directly |
| `Bash` (`cat`/`less`/heredoc) | | shell prints the secret; also bypasses Read-only `permissions.deny` |
| `Grep` | | `-A/-B/-C` context around a match leaks surrounding secret |
| `NotebookRead` | | notebook cell output |
| `mcp__*` | | MCP tool (e.g. SQL) returns secret rows; needs the mcp matcher |
| transcript replay | never (no hooks re-run) | `--resume`/compaction reload raw history |
