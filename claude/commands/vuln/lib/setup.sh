#!/usr/bin/env bash
# /vuln:setup — clone all non-archived tagemployerservices repos into ~/eBacon/vuln/
# and seed install-map.json from the template if missing.

set -uo pipefail

ORG="tagemployerservices"
ROOT="$HOME/eBacon/vuln"
MAP="$ROOT/install-map.json"
TEMPLATE="$HOME/.claude/commands/vuln/config/install-map.example.json"

# Preflight
for cmd in gh jq osv-scanner git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: missing required CLI: $cmd" >&2
    exit 1
  fi
done

if ! gh auth status >/dev/null 2>&1; then
  echo "error: gh CLI not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

mkdir -p "$ROOT"

if [ ! -f "$MAP" ]; then
  cp "$TEMPLATE" "$MAP"
  echo "[init] seeded $MAP from template"
fi

echo "[gh] listing non-archived repos in $ORG..."
repos=$(gh repo list "$ORG" --no-archived --limit 1000 --json name --jq '.[].name')

if [ -z "$repos" ]; then
  echo "error: no repos returned. Check 'gh repo list $ORG' manually." >&2
  exit 1
fi

cloned=0
existed=0
missing_map=()

for r in $repos; do
  dir="$ROOT/$r"
  if [ -d "$dir/.git" ]; then
    existed=$((existed + 1))
  else
    echo "[clone] $r (shallow)"
    if gh repo clone "$ORG/$r" "$dir" -- --depth 1 --single-branch --quiet 2>/dev/null; then
      cloned=$((cloned + 1))
    else
      echo "  failed — skipping" >&2
      continue
    fi
  fi

  if ! jq -e --arg n "$r" '.[$n]' "$MAP" >/dev/null 2>&1; then
    missing_map+=("$r")
  fi
done

echo
echo "===== Setup complete ====="
echo "  cloned this run: $cloned"
echo "  already present: $existed"
echo "  install-map:     $MAP"

if [ ${#missing_map[@]} -gt 0 ]; then
  echo
  echo "Repos missing from install-map.json (${#missing_map[@]}):"
  for r in "${missing_map[@]}"; do
    echo "  - $r"
  done
  echo
  echo "Edit $MAP and add an install command for each before running /vuln:scan."
fi
