#!/usr/bin/env bash
# /vuln:scan — for each cloned repo: pull → install → reset → osv-scanner.
# Writes per-repo JSON reports under ~/eBacon/vuln/_reports/<repo>/<ts>.json.

# Intentionally no `set -e`: one repo's failure must not abort the whole run.
set -uo pipefail

ROOT="$HOME/eBacon/vuln"
MAP="$ROOT/install-map.json"
REPORTS="$ROOT/_reports"
TS=$(date +%Y%m%dT%H%M%S)

if [ ! -f "$MAP" ]; then
  echo "error: $MAP not found. Run /vuln:setup first." >&2
  exit 1
fi

mkdir -p "$REPORTS"

summary="$REPORTS/_summary-$TS.txt"
: > "$summary"

total_repos=0
total_findings=0
errored=()

# Build the list of repos to scan.
# Positional args = explicit whitelist (case-insensitive match against clone dirnames).
# No args = every cloned repo.
declare -a target_repos=()
if [ "$#" -gt 0 ]; then
  for arg in "$@"; do
    arg_lc=$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]')
    match=""
    for dir in "$ROOT"/*/; do
      candidate=$(basename "$dir")
      candidate_lc=$(printf '%s' "$candidate" | tr '[:upper:]' '[:lower:]')
      if [ "$candidate_lc" = "$arg_lc" ]; then
        match="$candidate"
        break
      fi
    done
    if [ -z "$match" ]; then
      echo "error: no clone found for '$arg' in $ROOT" >&2
      exit 1
    fi
    target_repos+=("$match")
  done
  echo "[scope] scanning ${#target_repos[@]} repo(s): ${target_repos[*]}"
else
  for dir in "$ROOT"/*/; do
    candidate=$(basename "$dir")
    [ "$candidate" = "_reports" ] && continue
    [ -d "$dir/.git" ] || continue
    target_repos+=("$candidate")
  done
fi

for repo in "${target_repos[@]}"; do
  dir="$ROOT/$repo"
  [ -d "$dir/.git" ] || continue

  total_repos=$((total_repos + 1))
  echo "===== $repo ====="

  install_cmd=$(jq -r --arg n "$repo" '.[$n] // empty' "$MAP")
  if [ -z "$install_cmd" ]; then
    echo "  [skip] no install command in install-map.json"
    echo "$repo	SKIPPED (no install command)" >> "$summary"
    continue
  fi

  cd "$dir" || { echo "  [error] cannot cd"; continue; }

  # Detect default branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [ -z "$default_branch" ]; then
    echo "  [error] cannot detect default branch"
    echo "$repo	ERROR (no default branch)" >> "$summary"
    errored+=("$repo: default branch detection")
    cd - >/dev/null
    continue
  fi

  # Reset leftover state, then fetch latest shallow.
  # Shallow-friendly: fetch depth 1, hard-reset to origin (avoids merge logic).
  git reset --hard --quiet 2>/dev/null
  git clean -fd --quiet 2>/dev/null
  if ! git fetch --depth 1 origin "$default_branch" --quiet 2>/dev/null; then
    echo "  [error] git fetch failed"
    echo "$repo	ERROR (git fetch)" >> "$summary"
    errored+=("$repo: git fetch")
    cd - >/dev/null
    continue
  fi
  if ! git checkout "$default_branch" --quiet 2>/dev/null; then
    git checkout -B "$default_branch" "origin/$default_branch" --quiet 2>/dev/null || {
      echo "  [error] checkout $default_branch failed"
      echo "$repo	ERROR (checkout)" >> "$summary"
      errored+=("$repo: checkout $default_branch")
      cd - >/dev/null
      continue
    }
  fi
  git reset --hard "origin/$default_branch" --quiet 2>/dev/null

  echo "  [install] $install_cmd"
  if ! eval "$install_cmd" >/dev/null 2>&1; then
    echo "  [warn] install failed — proceeding to scan anyway"
  fi

  # Discard install side effects (lockfile churn)
  git reset --hard --quiet
  git clean -fd --quiet

  out_dir="$REPORTS/$repo"
  mkdir -p "$out_dir"
  out_file="$out_dir/$TS.json"

  echo "  [scan] osv-scanner → $out_file"
  # osv-scanner exits 1 when findings exist; capture stdout regardless
  osv-scanner scan source -r . --format json > "$out_file" 2>/dev/null
  scan_status=$?

  # Status 0 = no findings, 1 = findings present, anything else = scanner error
  if [ "$scan_status" -gt 1 ]; then
    echo "  [error] osv-scanner exit $scan_status"
    echo "$repo	ERROR (scanner exit $scan_status)" >> "$summary"
    errored+=("$repo: osv-scanner exit $scan_status")
    cd - >/dev/null
    continue
  fi

  count=$(jq '[.results[]?.packages[]?.vulnerabilities[]?] | length' "$out_file" 2>/dev/null || echo 0)
  count=${count:-0}
  total_findings=$((total_findings + count))

  printf "%s\t%s vulnerabilities\n" "$repo" "$count" >> "$summary"
  echo "  [done] $count findings"

  cd - >/dev/null
done

echo
echo "===== Summary ====="
column -t -s $'\t' < "$summary" 2>/dev/null || cat "$summary"
echo
echo "Repos scanned:  $total_repos"
echo "Total findings: $total_findings"
if [ ${#errored[@]} -gt 0 ]; then
  echo
  echo "Errored repos (${#errored[@]}):"
  for e in "${errored[@]}"; do echo "  - $e"; done
fi
echo
echo "Reports:        $REPORTS"
echo "Run timestamp:  $TS"
[ "$total_findings" -gt 0 ] && echo "Next:           /vuln:fix"
