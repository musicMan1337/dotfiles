#!/usr/bin/env bash
# Staged-diff secret-pattern scanner for pre-commit (E6). Scans ADDED lines only
# so pre-existing content in a touched file does not block. Blocks the commit on
# a shaped-secret match. Invoke from a pre-commit hook:
#     bash "<path>/secret-scan-precommit.sh" || exit 1
# or chain it from ~/dotfiles/git/hooks/pre-commit after the em-dash check.
# Escape hatch: ALLOW_SECRET=1 git commit ...
#
# This is a fail-closed *commit-time* catch, complementary to (not a substitute
# for) keeping secrets out of the tree via .gitignore + permissions.deny. Shaped
# patterns only; an unshaped secret (a DB password) will not match, so this is a
# net, not a wall. bash 3.2 safe.
# (scaffold: patches accidental secret commits that Write/Edit hooks miss because
#  the write came via Bash/other tooling; added 2026-08; retest if a fail-closed
#  pre-receive secret scanner is added server-side.)
set -u
[ "${ALLOW_SECRET:-0}" = "1" ] && exit 0

hits="$(LC_ALL=C git diff --cached -U0 --diff-filter=ACM 2>/dev/null | LC_ALL=C awk '
  /^\+\+\+ /{ f=$2; sub(/^b\//,"",f); next }
  /^(--- |@@)/{ next }
  /^\+/{
    s=substr($0,2)
    if (s ~ /AKIA[0-9A-Z]{16}/)                 print f ":  aws-access-key"
    else if (s ~ /sk_(live|test)_[0-9A-Za-z]{16,}/) print f ":  stripe-key"
    else if (s ~ /gh[pousr]_[0-9A-Za-z]{20,}/)  print f ":  github-token"
    else if (s ~ /xox[baprs]-[0-9A-Za-z-]{10,}/) print f ":  slack-token"
    else if (s ~ /-----BEGIN [A-Z ]*PRIVATE KEY-----/) print f ":  private-key"
    else if (s ~ /eyJ[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{10,}/) print f ":  jwt"
    else if (s ~ /(password|passwd|secret|api[_-]?key|token)[\"'"'"']?[[:space:]]*[:=][[:space:]]*[\"'"'"'][^\"'"'"']{8,}/) print f ":  assigned-secret-literal"
  }
')"

if [ -n "$hits" ]; then
  printf '\n\033[1;31m[commit blocked: possible secret in staged changes]\033[0m\n' >&2
  printf '%s\n' "$hits" >&2
  printf '\n  Move it to an ignored .env / secret store, or if it is a placeholder,\n' >&2
  printf '  override once: ALLOW_SECRET=1 git commit ...\n\n' >&2
  exit 1
fi
exit 0
