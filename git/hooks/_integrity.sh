#!/usr/bin/env bash
# Guards the guards: `lefthook install` writes its own shim into core.hooksPath
# and renames ours to <name>.old, silently disarming them (seen 2026-08-14).
# Usage: _integrity.sh check   -> exit 1 if a managed hook is not ours
#        _integrity.sh repair  -> put ours back (from .old, else from git)
# bash 3.2 safe. Fails OPEN on its own breakage; fails CLOSED only on real drift.
set -u

MODE="${1:-check}"
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." 2>/dev/null && pwd)" || ROOT=""
MARKER="dotfiles-managed-hook"
MANAGED="pre-commit commit-msg"

is_ours() { [ -f "$1" ] && grep -q "$MARKER" "$1" 2>/dev/null; }

drift=""
strays=""
for name in $MANAGED; do
  is_ours "$DIR/$name" || drift="$drift $name"
  [ -e "$DIR/$name.old" ] && strays="$strays $name.old"
done

[ -n "$drift$strays" ] || exit 0

if [ "$MODE" = "repair" ]; then
  for name in $drift; do
    live="$DIR/$name"; back="$live.old"
    if is_ours "$back"; then
      mv -f "$back" "$live" && chmod +x "$live" \
        && printf 'restored global git hook from backup: %s\n' "$name" >&2
    elif [ -n "$ROOT" ]; then
      git -C "$ROOT" checkout -- "git/hooks/$name" 2>/dev/null \
        && chmod +x "$live" \
        && printf 'restored global git hook from git: %s\n' "$name" >&2
    fi
    is_ours "$live" || printf 'FAILED to restore global git hook: %s\n' "$live" >&2
  done
  # A backup is only discardable once the live hook is ours again.
  for s in $strays; do
    name="${s%.old}"
    if is_ours "$DIR/$name" && is_ours "$DIR/$s"; then rm -f "$DIR/$s"; fi
  done
  exit 0
fi

[ "${SKIP_HOOK_INTEGRITY:-0}" = "1" ] && exit 0

printf '\n\033[1;31m[commit blocked: global git hooks were overwritten]\033[0m\n' >&2
[ -n "$drift" ] && printf '  no longer ours:%s\n' "$drift" >&2
[ -n "$strays" ] && printf '  foreign backup left behind:%s\n' "$strays" >&2
printf '  Repair: %s repair\n' "$DIR/_integrity.sh" >&2
printf '  Cause: a `lefthook install` (repo prepare/postinstall) clobbered core.hooksPath.\n' >&2
printf '  Override once: SKIP_HOOK_INTEGRITY=1 git commit ...\n\n' >&2
exit 1
