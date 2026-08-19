#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Denies the git commands that destroy work
# with no recovery path, before they run.
#
# Why this exists: nothing in the hook set covered destructive git. pr-guard.sh
# only denies `gh pr create`, so `git reset --hard`, `git clean -fd`, a force
# push, or `git checkout .` were all one tool call away from discarding
# uncommitted or unpushed work. The reflog does not help when the loss is
# uncommitted, and it does not help a collaborator whose commits a force push
# overwrote.
#
# Plain `git push` is deliberately ALLOWED: /git:pr, /dev:wrapup, and /dev:sql
# all push branches as part of normal flow. Only force and delete variants are
# denied.
#
# Rules are evaluated PER SEGMENT, same contract as scan-guard.sh: a flag may
# only arm a rule for the command it actually belongs to, so
# `rm -rf x; git status` cannot false-match.
#
# Escape hatch: prefix the command with ALLOW_DESTRUCTIVE_GIT=1 when the loss is
# the point (a deliberate history rewrite the user asked for). The prefix is a
# per-command opt-in, so it never disarms the rule for later commands.
#
# Same hookSpecificOutput contract as bash-egress-guard.sh and scan-guard.sh:
# deny fires even under --dangerously-skip-permissions; silence defers to normal
# permissions. Fail-open on missing deps. Applies to the main session and every
# subagent, since user-level PreToolUse hooks run for all sessions.
set -u

command -v jq >/dev/null 2>&1 || exit 0   # fail open: never break Bash on a missing dep

payload="$(cat)"
tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
[ "$tool_name" = "Bash" ] || exit 0

cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[ -z "$cmd" ] && exit 0

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Match against the CURRENT segment only. $seg is set by the loop below.
sm() { printf '%s' "$seg" | grep -Eq "$1"; }

CMDSTART='^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'

# `git` as this segment's command, allowing leading env assignments and the
# common global flags that precede the subcommand (-C <path>, -c k=v).
GIT="${CMDSTART}git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+))*[[:space:]]+"

sub() { sm "${GIT}$1"; }

while IFS= read -r seg; do
  [ -z "${seg//[[:space:]]/}" ] && continue

  # Per-command opt-in, checked on this segment only.
  printf '%s' "$seg" | grep -Eq '^[[:space:]]*ALLOW_DESTRUCTIVE_GIT=1[[:space:]]' && continue

  sub 'push([[:space:]]|$)' && sm '[[:space:]](--force([[:space:]]|=|$)|--force-with-lease|--force-if-includes|-f)([[:space:]]|$)' \
    && deny 'Denied by git-guard: force push overwrites commits on the remote, including a collaborator'"'"'s. Push normally, or rebase and push a new branch. If the rewrite is intended, re-run with ALLOW_DESTRUCTIVE_GIT=1 prefixed.'

  sub 'push([[:space:]]|$)' && sm '[[:space:]](--delete|--mirror|-d)([[:space:]]|$)' \
    && deny 'Denied by git-guard: this deletes a remote branch. Confirm with the user first; the branch may be someone else'"'"'s only copy. Intentional? Prefix ALLOW_DESTRUCTIVE_GIT=1.'

  sub 'push([[:space:]]|$)' && sm '[[:space:]]:[A-Za-z0-9._/-]+([[:space:]]|$)' \
    && deny 'Denied by git-guard: refspec push to an empty local ref deletes the remote branch. Prefix ALLOW_DESTRUCTIVE_GIT=1 if that is intended.'

  sub 'reset([[:space:]]|$)' && sm '[[:space:]]--hard([[:space:]]|$)' \
    && deny 'Denied by git-guard: reset --hard discards every uncommitted change with no reflog path back. Use `git stash` to park the work, or `git reset` (mixed) to keep the file contents. Prefix ALLOW_DESTRUCTIVE_GIT=1 if discarding is the point.'

  sub 'clean([[:space:]]|$)' && sm '[[:space:]]-[A-Za-z]*f' \
    && deny 'Denied by git-guard: clean -f deletes untracked files, which are not in git at all and are unrecoverable. List them first with `git clean -n`. Prefix ALLOW_DESTRUCTIVE_GIT=1 to proceed.'

  sub 'branch([[:space:]]|$)' && sm '([[:space:]]-[A-Za-z]*D[A-Za-z]*([[:space:]]|$)|[[:space:]]--delete[[:space:]]+.*--force|[[:space:]]--force[[:space:]]+.*--delete)' \
    && deny 'Denied by git-guard: branch -D force-deletes a branch whose commits may be unmerged. Use `git branch -d` (safe delete, refuses when unmerged). Prefix ALLOW_DESTRUCTIVE_GIT=1 to force it.'

  sub '(checkout|restore)([[:space:]]|$)' && sm '[[:space:]](--[[:space:]]+)?\.([[:space:]]|$)' \
    && ! sm '[[:space:]]--staged([[:space:]]|$)' \
    && deny 'Denied by git-guard: this discards every uncommitted change in the tree. Name the specific file, or stash instead. Prefix ALLOW_DESTRUCTIVE_GIT=1 if a full discard is intended.'

  sub 'stash([[:space:]]|$)' && sm '[[:space:]](clear|drop)([[:space:]]|$)' \
    && deny 'Denied by git-guard: this destroys stashed work that exists nowhere else. Inspect with `git stash list` and `git stash show -p` first. Prefix ALLOW_DESTRUCTIVE_GIT=1 to proceed.'

  sub '(filter-branch|filter-repo)([[:space:]]|$)' \
    && deny 'Denied by git-guard: history rewrite across the repo. This needs an explicit plan and the user'"'"'s go-ahead. Prefix ALLOW_DESTRUCTIVE_GIT=1 once they have given it.'

  sub 'reflog([[:space:]]|$)' && sm '[[:space:]]expire([[:space:]]|$)' \
    && deny 'Denied by git-guard: expiring the reflog removes the recovery path for every other destructive operation. Prefix ALLOW_DESTRUCTIVE_GIT=1 to proceed.'

  sub 'update-ref([[:space:]]|$)' && sm '[[:space:]]-d([[:space:]]|$)' \
    && deny 'Denied by git-guard: deleting a ref directly orphans its commits. Use the branch/tag commands so the reflog records it. Prefix ALLOW_DESTRUCTIVE_GIT=1 to proceed.'

done <<< "$(printf '%s' "$cmd" | tr ';|&()' '\n\n\n\n\n')"

exit 0
