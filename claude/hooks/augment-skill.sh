#!/bin/bash
# PreToolUse hook for the Skill tool.
#
# Auto-pairs any base skill X with a personal `augment:X` skill when one exists,
# forcing the augment layer to run in tandem with the base skill (e.g. the
# built-in `artifact-design` always pulls in `augment:artifact-design`).
#
# Convention: augment:<name> lives at ~/.claude/commands/augment/<name>/SKILL.md
# Add a new augment/<name>/SKILL.md and it gets force-paired automatically; no
# edit to this hook or settings.json is needed.

# Fail open: never block a Skill invocation because of this hook.
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"

# The Skill tool carries the skill name in tool_input.skill (older builds:
# skillName). Accept either.
skill="$(printf '%s' "$payload" | jq -r '.tool_input.skill // .tool_input.skillName // empty')"

[ -z "$skill" ] && exit 0

# Don't recurse when the augment skill itself is being invoked.
case "$skill" in
  augment:*) exit 0 ;;
esac

# Only act if a matching augment skill is actually installed.
[ -f "$HOME/.claude/commands/augment/$skill/SKILL.md" ] || exit 0

jq -nc --arg s "$skill" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: ("A personal augmentation skill `augment:\($s)` is installed for `\($s)`. Invoke it now via the Skill tool, in tandem with `\($s)`, and apply its enhancements on top of the base skill output. The base skill still runs as normal.")
  }
}'
exit 0
