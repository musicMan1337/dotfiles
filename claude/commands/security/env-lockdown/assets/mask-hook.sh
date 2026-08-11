#!/usr/bin/env bash
# ============================================================================
# SEATBELT, NOT A BOUNDARY. PostToolUse mask hook (updatedToolOutput).
#
# Verified 2026-08-11 (CC 2.1.227): this masking is FAIL-OPEN. If this hook
# exits non-zero OR exceeds its configured `timeout`, Claude Code delivers the
# RAW tool output to the model AND writes it to the transcript. A caller who can
# force an error (a payload that breaks jq) or a timeout (an oversized file)
# defeats the mask. Use permissions.deny (fail-closed) or environment isolation
# as the actual boundary; this is defense-in-depth on top.
#
# On SUCCESS it does prevent transcript spill (only the masked value persists),
# which is its real value. Known-value redaction catches unshaped secrets a
# regex cannot; it is defeated by encoding (base64/json/split) and derived
# tokens. Pattern redaction catches shaped secrets only.
#
# (scaffold: patches the lack of a fail-closed content filter on tool output;
#  added 2026-08; retest when CC ships a fail-closed output redaction primitive.)
#
# Config via env:
#   MASK_SECRET_FILE  path to a file of literal secret VALUES, one per line,
#                     generated at runtime from the same source the app uses.
#                     NEVER commit this file. Absent -> pattern redaction only.
#   MASK_MODE         test knob: ok (default) | fail | timeout. For the
#                     fail-open probe in _refs/controls.md. Leave unset in prod.
# ============================================================================
set -u
command -v jq >/dev/null 2>&1 || exit 0   # no jq -> emit nothing -> fail-open (documented)

mode="${MASK_MODE:-ok}"
payload="$(cat)"
case "$mode" in
  fail)    exit 1 ;;
  timeout) sleep 30; exit 0 ;;
esac

resp="$(printf '%s' "$payload" | jq -c '.tool_response' 2>/dev/null)"
[ -z "$resp" ] || [ "$resp" = "null" ] && exit 0   # nothing to mask, pass through

# --- known-value redaction (exact string) --------------------------------
# Build a sed program of literal-value replacements, longest first so a value
# that is a substring of another is handled correctly. Escape sed metachars.
if [ -n "${MASK_SECRET_FILE:-}" ] && [ -f "$MASK_SECRET_FILE" ]; then
  sedprog="$(awk '{ print length, $0 }' "$MASK_SECRET_FILE" \
    | sort -rn | cut -d' ' -f2- \
    | awk 'length($0) >= 6 {                       # skip trivially short values
        v=$0; gsub(/[\/&.*[\]^$]/,"\\\\&",v);       # escape sed BRE metachars
        printf "s/%s/[REDACTED:VALUE]/g;\n", v }')"
  if [ -n "$sedprog" ]; then
    resp="$(printf '%s' "$resp" | sed "$sedprog" 2>/dev/null || printf '%s' "$resp")"
  fi
fi

# --- pattern redaction (shaped secrets) ----------------------------------
# Kept conservative to limit false positives. Extend per environment.
resp="$(printf '%s' "$resp" | sed -E \
  -e 's/AKIA[0-9A-Z]{16}/[REDACTED:AWS_KEY]/g' \
  -e 's/sk_(live|test)_[0-9A-Za-z]{16,}/[REDACTED:STRIPE_KEY]/g' \
  -e 's/gh[pousr]_[0-9A-Za-z]{20,}/[REDACTED:GITHUB_TOKEN]/g' \
  -e 's/eyJ[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{10,}/[REDACTED:JWT]/g' \
  -e 's/xox[baprs]-[0-9A-Za-z-]{10,}/[REDACTED:SLACK_TOKEN]/g' \
  2>/dev/null || printf '%s' "$resp")"

# Re-emit as updatedToolOutput. Because we only string-replaced inside the
# already-valid JSON, the shape is preserved (see F4 in _refs/controls.md).
if printf '%s' "$resp" | jq -e . >/dev/null 2>&1; then
  jq -cn --argjson r "$resp" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse", updatedToolOutput:$r}}'
else
  # Redaction produced invalid JSON: emit nothing rather than a malformed shape
  # (which would error = fail-open anyway). Pass through, documented seatbelt.
  exit 0
fi
