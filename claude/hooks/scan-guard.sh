#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Denies unfiltered full-tree scan commands
# before they run: they mass-read files (including .git/node_modules/dot dirs),
# which is wasteful and trips Sophos CryptoGuard as "Probable Ransomware"
# (2026-08-07: two parallel repo sweeps got the claude process killed mid-task;
# same class as the 2026-07-01 incident).
#
# Same hookSpecificOutput contract as bash-egress-guard.sh: deny fires even
# under --dangerously-skip-permissions; silence defers to normal permissions.
# Fail-open on missing deps. Applies to the main session and every subagent,
# since user-level PreToolUse hooks run for all sessions on this machine.
set -u

command -v jq >/dev/null 2>&1 || exit 0   # fail open: never break Bash on a missing dep

payload="$(cat)"
tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
[ "$tool_name" = "Bash" ] || exit 0

cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[ -z "$cmd" ] && exit 0

m() { printf '%s' "$cmd" | grep -Eq "$1"; }

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Command-position matcher: start of line/segment only, so `echo "find x"` or
# `docker ps | grep foo` args don't false-match. Misses `xargs grep -r` shapes,
# but those are bounded by the (guarded) find/glob that feeds them.
CMDPOS='(^[[:space:]]*|[;&|(][[:space:]]*)'

# Recursive-grep detection: grep/egrep/fgrep at command position with an -r/-R
# flag cluster or --recursive. `git grep` never matches (git is the command).
grep_r() {
  m "${CMDPOS}(grep|egrep|fgrep)[[:space:]]" \
    && m "[[:space:]](-[A-Za-z]*[rR][A-Za-z]*([[:space:]]|$)|--(dereference-)?recursive)"
}

# --- 1. Any scan rooted at home / root / /Users: always too broad ------------
if m "${CMDPOS}(rg|fd|find)[[:space:]]" || grep_r; then
  if m "[[:space:]](~|\\\$HOME|/Users(/derek)?|/)([[:space:]]|$)"; then
    deny "Scan rooted at home or filesystem root is blocked: Sophos CryptoGuard flags mass file reads as ransomware and kills the claude process (happened 2026-08-07). Scope the search to a specific repo or subdirectory."
  fi
fi

# --- 2. Recursive grep without --include: reads .git/node_modules/everything -
if grep_r && ! m "\--include"; then
  deny "Recursive grep without --include reads every file in the tree (.git, node_modules, dot dirs) and trips Sophos CryptoGuard. Use the Grep tool instead (ripgrep-backed: respects .gitignore, skips dot files), or add --include='*.ext' AND a specific subdirectory."
fi

# --- 3. rg with ignore/hidden filtering disabled ------------------------------
if m "${CMDPOS}rg[[:space:]]" \
   && m "[[:space:]](--no-ignore(-[a-z]+)?|--hidden|--unrestricted|-u{1,3})([[:space:]]|$)"; then
  deny "rg with --no-ignore/--hidden/-u disables the .gitignore and dot-file filters and mass-reads the tree (Sophos CryptoGuard trigger). Drop the flag; rg searches an ignored or hidden path when you pass that path explicitly as an argument."
fi

# --- 4. fd with ignore/hidden filtering disabled ------------------------------
if m "${CMDPOS}fd[[:space:]]" \
   && m "[[:space:]](--no-ignore(-[a-z]+)?|--hidden|--unrestricted|-[HIu])([[:space:]]|$)"; then
  deny "fd with -H/-I/-u/--no-ignore/--hidden traverses .git and ignored dirs. Drop the flag and pass the specific hidden/ignored path explicitly, or use the Glob tool."
fi

# --- 5. find with no narrowing primary: full-tree traversal -------------------
if m "${CMDPOS}find[[:space:]]" \
   && ! m "\-(i?name|i?path|i?regex|maxdepth|mindepth|newer|newermt|mmin|mtime|samefile|inum|prune|empty)\b"; then
  deny "Unfiltered find traverses the entire tree including .git and node_modules. Add -name/-path/-maxdepth (with -prune for bulk dirs), or use the Glob tool which skips ignored and dot files."
fi

exit 0
