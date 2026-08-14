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

  # Resolve the repo's OWN hooks dir. Deliberately not `git rev-parse --git-path
  # hooks`: that honors core.hooksPath and resolves right back to this directory.
  # In a worktree $root/.git is a FILE, so $root/.git/hooks does not exist and
  # the real hooks live in the common dir. (2026-08-14: this is why lefthook was
  # silently dead in every Viper worktree, not just on fresh clones.)
  local common; common="$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)" || return 0
  case "$common" in /*) ;; *) common="$root/$common" ;; esac

  # If this repo sets its own core.hooksPath (husky/lefthook), we are not even
  # running; when we ARE running, that hooks dir is the only thing we shadow.
  local local_hook="$common/hooks/$name"
  if [ -x "$local_hook" ] && [ "$local_hook" != "$0" ]; then
    "$local_hook" "$@"
    return $?
  fi

  chain_lefthook "$root" "$name" "$@"
}

# Run lefthook directly when it has no installed hook file to chain to.
# `lefthook install` REFUSES to write hooks while a global core.hooksPath is set
# (it will not create files git would ignore), and a repo's `prepare` script
# typically swallows that with `|| true`. On a fresh clone that leaves nothing
# for chain_local_hook to find, so the repo's entire lint gate silently
# disappears with only a hint buried in npm output. Calling lefthook ourselves
# makes `lefthook install` unnecessary. Fails OPEN throughout: a missing binary
# or config must never brick a commit.
chain_lefthook() {
  local root="$1" name="$2"; shift 2

  local cfg="" f
  for f in lefthook.yml lefthook.yaml .lefthook.yml .lefthook.yaml; do
    if [ -f "$root/$f" ]; then cfg="$root/$f"; break; fi
  done
  [ -n "$cfg" ] || return 0

  # Only run hooks the config actually declares, so an undeclared name is a
  # no-op here instead of a bet on lefthook's exit code for unknown hooks.
  grep -Eq "^[[:space:]]*[\"']?${name}[\"']?[[:space:]]*:" "$cfg" || return 0

  local bin=""
  if command -v lefthook >/dev/null 2>&1; then
    bin="lefthook"
  elif [ -x "$root/node_modules/.bin/lefthook" ]; then
    bin="$root/node_modules/.bin/lefthook"
  else
    return 0
  fi

  ( cd "$root" && "$bin" run "$name" "$@" )
  return $?
}
