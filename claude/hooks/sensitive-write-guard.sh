#!/usr/bin/env bash
# PreToolUse hook (matcher: Write|Edit). Denies Write/Edit into machine-
# persistence and config-integrity locations that carry no git-visible diff, so
# the permission system cannot be used to silently plant login/persistence
# payloads or rewrite its own untracked config.
#
# Denies:  ~/.ssh/**, ~/Library/LaunchAgents/**, **/.git/hooks/**,
#          ~/.claude/settings.local.json, ~/.claude/tmp/subagent-slots/**
# Allows:  everything else, including ~/dotfiles/claude/** (the git-tracked
#          /update-config path) which stays writable and is diff-observable.
#
# The tracked harness symlinks (~/.zshrc, ~/.claude/settings.json, existing
# ~/.claude/hooks/*) write through into the public git repo and DO show in
# `git status`, so they rely on detection (check-hook-wiring.js + the diff), not
# on this deny. Only the untracked surfaces above get a hard block.
#
# (scaffold: patches Write(**)/Edit(**) protecting neither machine autostart nor
#  its own config; added 2026-07; retest when CC adds path-scoped Write deny
#  that also covers Bash redirects)
set -u

command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
case "$tool_name" in Write|Edit) ;; *) exit 0 ;; esac

fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty')"
[ -z "$fp" ] && exit 0

home="$HOME"
# Normalize a leading ~ to $HOME so ~/... and absolute forms are compared alike.
case "$fp" in "~"/*) fp="$home/${fp#\~/}" ;; "~") fp="$home" ;; esac

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

case "$fp" in
  "$home"/.ssh/*|"$home"/.ssh)
    deny "Writing into ~/.ssh is blocked (key-store integrity). If you meant a repo file, use its path under the working directory." ;;
  "$home"/Library/LaunchAgents/*)
    deny "Writing a LaunchAgent is blocked (login-persistence surface); this is never part of editing product code." ;;
  */.git/hooks/*)
    deny "Writing a git hook is blocked (executes on every git operation); install repo hooks yourself if intended." ;;
  "$home"/.claude/settings.local.json)
    deny "Editing ~/.claude/settings.local.json is blocked (untracked permission config; no git diff would show the change). Change the tracked dotfiles settings instead." ;;
  "$home"/.claude/tmp/subagent-slots/*)
    deny "Writing subagent-gate slot files is blocked (would let a session forge its own concurrency accounting)." ;;
esac

exit 0
