# Shared helpers for the global hooks (sourced, not executed).
# These hooks run for EVERY repo on this machine (core.hooksPath). They must:
#   - block ONLY on a real detected violation,
#   - never brick commits because of their own internal error (fail-open on bug),
#   - chain to any repo-local .git/hooks/<name> so a global hooksPath does not
#     shadow husky / lefthook / native hooks a repo relies on.
#
# (scaffold: patches model-introduced em-dash + self-attribution leaking into
#  committed files/messages despite explicit CLAUDE.md rules; the tool-boundary
#  hooks miss Bash heredocs / other writers / commit messages. added 2026-08;
#  retest when a model release stops emitting em-dash + attribution unprompted.)

# The em-dash (U+2014) as raw UTF-8 bytes, built without typing the character
# (the char itself is banned from file contents). Octal for max portability.
EMDASH="$(printf '\342\200\224')"

# Extensions we govern for em-dash. Kept to source + prose we author; skips
# data/vendored/binary where an em-dash is likely legitimate content.
GUARDED_EXT_RE='\.(md|markdown|txt|js|jsx|ts|tsx|mjs|cjs|json|jsonc|css|scss|less|html?|py|rb|go|rs|java|cs|php|sh|bash|zsh|sql|ya?ml|toml|ini|xml|vue|svelte|c|h|cpp|hpp)$'

# Print a red-flag block header + detail lines ($2..). No em-dash in our output.
guard_die() {
  printf '\n\033[1;31m[commit blocked: %s]\033[0m\n' "$1" >&2
  shift
  for line in "$@"; do printf '  %s\n' "$line" >&2; done
  printf '\n' >&2
}

# Chain to a repo-local hook of the same name if present and executable, so
# global hooksPath does not silently disable a repo's own hooks. $1 = hook name,
# remaining args = original hook args. Returns the local hook's exit status.
chain_local_hook() {
  local name="$1"; shift
  local root; root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 0
  local local_hook="$root/.git/hooks/$name"
  # If this repo sets its own core.hooksPath (husky/lefthook), we are not even
  # running; when we ARE running, .git/hooks is the only thing we could shadow.
  if [ -x "$local_hook" ] && [ "$local_hook" != "$0" ]; then
    "$local_hook" "$@"
    return $?
  fi
  return 0
}
