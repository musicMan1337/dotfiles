#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Denies raw `gh pr create` so PR authoring
# always routes through the /git:pr skill, which owns the house PR format and
# the absolute no-attribution rule (claude/commands/git/pr.md).
#
# Why this exists: `git:pr` was marked user-invocable-only in skillOverrides,
# so a model-initiated Skill(/git:pr) was refused at the config layer. The
# model then did the task the direct way (`gh pr create --body-file ...`),
# producing a PR body that never saw pr.md's rules. The override is gone now;
# this hook is the backstop that keeps the fallback path from reappearing.
#
# Escape hatch: the skill itself shells out to `gh pr create`, so a blanket
# deny would block the very path we want. Commands carrying the PR_VIA_SKILL=1
# marker pass through. Same shape as the pre-commit hook's ALLOW_EMDASH=1.
#
# Same hookSpecificOutput contract as scan-guard.sh: deny fires even under
# --dangerously-skip-permissions; silence defers to normal permissions.
# Fail-open on missing deps.
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

# Skill-sanctioned invocation: let it through untouched.
m '(^|[[:space:]])PR_VIA_SKILL=1([[:space:]]|$)' && exit 0

# Command-position matcher, same as scan-guard.sh: start of line or after a
# separator, so `echo "gh pr create"` and `grep 'gh pr create' file` don't match.
CMDPOS='(^[[:space:]]*|[;&|(][[:space:]]*)'

# Read-only subcommands (view/list/status/diff/checks) are never touched: the
# `create` literal is required.
if m "${CMDPOS}gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)"; then
  deny "Raw 'gh pr create' is blocked. Use the /git:pr skill: it owns the house PR title/body format and the absolute rule that no PR may reference a model, agent, session, or tool. Writing the body directly skips both. If you are executing inside that skill, prefix the command with PR_VIA_SKILL=1."
fi

# `gh pr edit` is only blocked when it rewrites governed prose (title/body).
# Metadata edits (labels, reviewers, assignees, base, milestone) carry no house
# format and stay allowed, so the verb alone is never enough to deny.
# Flags: --title/-t, --body/-b, --body-file/-F.
if m "${CMDPOS}gh[[:space:]]+pr[[:space:]]+edit([[:space:]]|$)" \
   && m "[[:space:]](--title|--body(-file)?|-[tbF])([[:space:]=]|$)"; then
  deny "Editing a PR title or body with raw 'gh pr edit' is blocked: the same house format and no-attribution rules that govern PR creation govern rewrites. Use /git:pr (or /git:pr-suggestions for review-comment work). Metadata-only edits (--add-label, --add-reviewer, --base, --milestone) are allowed. If you are executing inside that skill, prefix the command with PR_VIA_SKILL=1."
fi

exit 0
