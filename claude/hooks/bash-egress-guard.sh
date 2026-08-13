#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). The real wall for the few Bash actions that
# are irreversible, leave the machine, or hit prod. Deny-literal permission
# rules are prefix-matched and bypassed by path prefix / flag reorder / command
# substitution; this hook inspects the resolved command instead.
#
# Emits the CC hookSpecificOutput contract (same shape execute-sp-confirm.sh and
# subagent-gate.js use), so deny/ask fire even under --dangerously-skip-permissions.
#   deny  -> blocked, reason fed back to the model
#   ask   -> user prompted (in a bypass session an ask may fall through to allow;
#            treated as best-effort interrupt, never as the sole wall)
#   (else) exit 0 with no output -> defer to normal permission flow
#
# (scaffold: patches Bash(*) having no content gate - deny literals leak via
#  path prefix / flag reorder / substitution; added 2026-07; retest on model
#  upgrade or when CC ships native command-class deny)
set -u

command -v jq >/dev/null 2>&1 || exit 0   # fail open: never break Bash on a missing dep

payload="$(cat)"
tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
[ "$tool_name" = "Bash" ] || exit 0

cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[ -z "$cmd" ] && exit 0

# grep -E test against the raw command string.
m() { printf '%s' "$cmd" | grep -Eq "$1"; }

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}
ask() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  exit 0
}

READERS='(cat|xxd|od|hexdump|strings|base64|head|tail|less|more|nl|tac|gpg|openssl|tee|cp|mv|dd)'
NETVERB='(curl|wget|nc|ncat|socat|scp|rsync|ftp|sftp)'

# --- DENY: never-legit, irreversible, or outward -----------------------------

# 1. SSH private-key read or any ssh-material exfil. `.pub` and known_hosts/config
#    are excluded from the read rule; any network verb touching ~/.ssh is denied.
if m "\.ssh/id_[A-Za-z0-9_]+([^.A-Za-z0-9]|$)"; then
  m "\b${READERS}\b" && deny "Reading SSH private-key bytes is never part of a legitimate task (ssh/git use the key via the agent, not by catting it). Blocked to prevent key exfiltration."
fi
if m "\.ssh/" && m "\b${NETVERB}\b"; then
  deny "Sending anything from ~/.ssh over the network is blocked (key/exfil protection)."
fi

# 2. .env exfil over the network (local reads stay allowed; dev needs them).
if m "(^|[^A-Za-z0-9_.])\.env" && ! m "\.env\.(example|sample|local|dist|template)" && m "\b${NETVERB}\b"; then
  deny "Uploading a .env file off the machine is blocked (secret exfil protection)."
fi

# 3. Writes into machine-persistence / config-integrity locations via Bash
#    (Write/Edit are covered by sensitive-write-guard.sh; this closes the
#    shell-redirect path: echo >> ~/Library/LaunchAgents, cp payload into it, etc.)
#    Two precise checks so an unrelated redirect elsewhere in a compound command
#    does not false-deny: (a) redirect target IS a sensitive path, (b) a
#    copy/move/link/chmod names a sensitive path.
SENS='(\.ssh/|Library/LaunchAgents/|\.git/hooks/|\.claude/(settings[^/]*\.json|hooks/|tmp/subagent-slots/))'
if m ">>?[[:space:]]*[^ |&;]*${SENS}" || m "\b(cp|mv|ln|install|tee|chmod)\b[^|;&]*${SENS}"; then
  deny "Writing into ~/.ssh, ~/Library/LaunchAgents, .git/hooks, or the ~/.claude config tree is blocked (persistence / config-tamper protection). Edit the git-tracked dotfiles repo path instead."
fi

# 4. Package publish (live authToken in ~/.npmrc; catches path-prefix + yarn + mid-compound).
m "\b(npm|pnpm|yarn)\b[^|;&]*\bpublish\b" && deny "Publishing a package is blocked; run it yourself if a real release is intended."

# 5. Recursive+forced rm whose target escapes {cwd-subtree, /tmp, scratchpad}.
#    Relative targets (build, dist, ./x) are allowed; home-absolute / tilde / root
#    targets and the `cd ~ && rm -rf .` pattern are denied.
#    Flags are matched as whole tokens WITHIN the rm segment: an unanchored
#    -[A-Za-z]*[rR] also matches a hyphen inside an argument (fnm's
#    node-versions/, pre-render/) or a flag on an unrelated command later in the
#    compound, which denied plain single-file `rm -f <path>` (2026-08).
RM_FLAG_R='(^|[[:space:]])(-[A-Za-z]*[rR][A-Za-z]*|--recursive)([[:space:]]|$)'
RM_FLAG_F='(^|[[:space:]])(-[A-Za-z]*f[A-Za-z]*|--force)([[:space:]]|$)'
HOME_ABS=$'[[:space:]]["\']?(~|\\$HOME|/Users/derek|/)([[:space:]/\'"]|$)'
seg_m() { printf '%s' "$seg" | grep -Eq "$1"; }

while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  seg_m "$RM_FLAG_R" || continue
  seg_m "$RM_FLAG_F" || continue
  if seg_m "$HOME_ABS"; then
    deny "Recursive delete targeting your home directory, an absolute home path, or root is blocked. Scope the rm to a relative path under the working directory, or use scratchpad/tmp."
  fi
  if m "\bcd[[:space:]]+(~|\\\$HOME|/Users/derek|/)([[:space:]]|;|&|$)" && seg_m "[[:space:]](\.|\*)([[:space:]]|$)"; then
    deny "A cd to home or root followed by a recursive delete of the current directory or a bare glob is blocked (home-wipe pattern)."
  fi
done <<EOF
$(printf '%s' "$cmd" | grep -oE '\brm\b[^|;&]*')
EOF
# find-based mass delete rooted at home/root.
m "\bfind\b[[:space:]]+(~|\\\$HOME|/Users/derek|/)[^|;&]*-delete" && deny "find -delete rooted at home or root is blocked."

# --- ASK: deliberate, outward or history-altering; interrupt once ------------

m "\bgit[[:space:]]+push\b[^|;&]*(--force|--force-with-lease|-f\b|[[:space:]]\+)" \
  && ask "Force-push rewrites remote history. Confirm the target ref before proceeding."
m "\bgh[[:space:]]+pr[[:space:]]+merge\b" \
  && ask "Merging a PR can trigger a prod tag/release pipeline. Confirm before merging."
m "\bgh[[:space:]]+api\b[^|;&]*[/]merge\b" \
  && ask "This gh api call merges a PR. Confirm before proceeding."
m "\bgh[[:space:]]+workflow[[:space:]]+run\b" \
  && ask "Dispatching a GitHub Actions workflow runs real CI/CD. Confirm the target workflow."
m "\bgh[[:space:]]+pr[[:space:]]+comment\b[^|;&]*/case-note" \
  && ask "This posts a note to a PRODUCTION case. Confirm the note text (show it as numbered options first)."
m "\bgit[[:space:]]+config[[:space:]]+--global\b" \
  && ask "Changing global git config (transport/identity/credential helper) affects every repo. Confirm."
m "\bclaude\b[^|;&]*(--print\b|[[:space:]]-p\b)" \
  && ask "Spawning a non-interactive claude print session starts a full-authority nested session. Confirm."

exit 0
