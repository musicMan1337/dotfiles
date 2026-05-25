#!/usr/bin/env bash
# Claude Code statusLine command
# Displays: model | session cost / today cost / block cost (time left) | context tokens (usage %) | cwd | git status

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"' | sed 's/ context)/)/; s/(1M )/(1M)/')
# Effort: check statusline JSON first, then settings, default to "medium"
effort=$(echo "$input" | jq -r '.effortLevel // empty')
[ -z "$effort" ] && effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
[ -z "$effort" ] && effort="medium"
# Compute real context usage including output tokens
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_tokens=$(echo "$input" | jq -r '
  .context_window |
  if .current_usage then
    (.current_usage.input_tokens + .current_usage.output_tokens + .current_usage.cache_creation_input_tokens + .current_usage.cache_read_input_tokens)
  else
    empty
  end
' 2>/dev/null)
if [ -n "$ctx_tokens" ] && [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
  used_pct=$(echo "$ctx_tokens $ctx_size" | awk '{printf "%.0f", ($1/$2)*100}')
else
  used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
fi
cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""')

# Session cost from statusline JSON
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Shorten home path
short_cwd="${cwd/#$HOME/~}"

format_num() {
  printf "%'d" "$1" 2>/dev/null || echo "$1"
}

format_cost() {
  printf "\$%.2f" "$1" 2>/dev/null || echo "\$0.00"
}

# --- Cost calculation from JSONL files (cached for 30s) ---
CACHE_FILE="/tmp/claude-statusline-costs.json"
CACHE_TTL=30
JQ_FILTER="$HOME/.claude/scripts/statusline-costs.jq"

refresh_costs() {
  export TODAY_START
  TODAY_START="$(date -u +%Y-%m-%d)T00:00:00"
  export FIVE_H_AGO
  FIVE_H_AGO=$(date -u -v-5H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d '5 hours ago' +%Y-%m-%dT%H:%M:%S)

  result=$(find ~/.claude/projects -name "*.jsonl" -print0 2>/dev/null \
    | xargs -0 grep -h '"type":"assistant"' 2>/dev/null \
    | jq -s -f "$JQ_FILTER" 2>/dev/null)
  if [ -n "$result" ] && [ "$result" != "null" ]; then
    echo "$result" > "$CACHE_FILE"
  fi
}

# Check cache age
need_refresh=1
if [ -f "$CACHE_FILE" ]; then
  cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  cache_age=$(( $(date +%s) - cache_mtime ))
  [ "$cache_age" -lt "$CACHE_TTL" ] && need_refresh=0
fi

[ "$need_refresh" -eq 1 ] && refresh_costs

# Read cached values
today_cost=""
block_cost=""
block_time_left=""
if [ -f "$CACHE_FILE" ]; then
  today_cost=$(jq -r '.today_cost // empty' "$CACHE_FILE" 2>/dev/null)
  block_cost=$(jq -r '.block_cost // empty' "$CACHE_FILE" 2>/dev/null)
  block_earliest=$(jq -r '.block_earliest // empty' "$CACHE_FILE" 2>/dev/null)

  # Calculate time remaining in 5h block
  if [ -n "$block_earliest" ] && [ "$block_earliest" != "null" ]; then
    # Block end = earliest timestamp + 5 hours
    earliest_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%S" "${block_earliest%%.*}" +%s 2>/dev/null \
      || date -u -d "${block_earliest}" +%s 2>/dev/null || echo 0)
    if [ "$earliest_epoch" -gt 0 ] 2>/dev/null; then
      block_end=$(( earliest_epoch + 18000 ))
      now=$(date +%s)
      remaining=$(( block_end - now ))
      if [ "$remaining" -gt 0 ]; then
        hours=$(( remaining / 3600 ))
        mins=$(( (remaining % 3600) / 60 ))
        block_time_left="${hours}h ${mins}m left"
      fi
    fi
  fi
fi

# Build cost segment
cost_seg=""
if [ -n "$session_cost" ] && [ "$session_cost" != "0" ]; then
  cost_seg="$(format_cost "$session_cost") session"
fi
if [ -n "$today_cost" ] && [ "$today_cost" != "0" ]; then
  [ -n "$cost_seg" ] && cost_seg+=" / "
  cost_seg+="$(format_cost "$today_cost") today"
fi
if [ -n "$block_cost" ] && [ "$block_cost" != "0" ]; then
  [ -n "$cost_seg" ] && cost_seg+=" / "
  cost_seg+="$(format_cost "$block_cost") block"
  [ -n "$block_time_left" ] && cost_seg+=" ($block_time_left)"
fi

# Context info
ctx=""
if [ -n "$ctx_tokens" ] && [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  token_k=$(( ctx_tokens / 1000 ))
  ctx="${token_k}K (${used_int}%)"
elif [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx="${used_int}%"
fi

# Git info (all with GIT_OPTIONAL_LOCKS=0 to avoid blocking)
git_seg=""
if [ -n "$cwd" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    staged=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    stash=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
    upstream=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    ahead=0 behind=0
    if [ -n "$upstream" ]; then
      ahead=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
      behind=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
    fi

    details=()
    [ "$staged" -gt 0 ] 2>/dev/null && details+=("●${staged}")
    [ "$modified" -gt 0 ] 2>/dev/null && details+=("+${modified}")
    [ "$untracked" -gt 0 ] 2>/dev/null && details+=("…${untracked}")
    [ "$stash" -gt 0 ] 2>/dev/null && details+=("⚑${stash}")
    [ "$ahead" -gt 0 ] 2>/dev/null && details+=("⇡${ahead}")
    [ "$behind" -gt 0 ] 2>/dev/null && details+=("⇣${behind}")

    git_seg="⎇ ${branch}"
    if [ ${#details[@]} -gt 0 ]; then
      IFS=' '
      git_seg+=" [${details[*]}]"
    fi
  fi
fi

# Effort bars: colored █ blocks - active=orange, inactive=gray
c_orange=$'\033[38;5;214m'
c_red=$'\033[38;5;196m'
c_gray=$'\033[38;5;240m'
c_reset=$'\033[0m'
b="${c_orange}█${c_reset}"   # active bar
g="${c_gray}█${c_reset}"     # inactive bar
r="${c_red}█${c_reset}"      # ultrathink bar
case "$effort" in
  low)        effort_bars="${b}${g}${g}" ;;
  medium)     effort_bars="${b}${b}${g}" ;;
  high)       effort_bars="${b}${b}${b}" ;;
  ultrathink) effort_bars="${r}${r}${r}" ;;
  *)          effort_bars="${b}${b}${g}" ;;
esac

# Build output: model | costs | context | directory | git (single line)
parts=()
model_seg="${model} ${effort_bars}"
parts+=("🤖 ${model_seg}")
[ -n "$cost_seg" ] && [ ! -f "$HOME/.claude/.hide-costs" ] && parts+=("💰 ${cost_seg}")
[ -n "$ctx" ] && parts+=("🧠 ${ctx}")
parts+=("📂 ${short_cwd}")
[ -n "$git_seg" ] && parts+=("${git_seg}")

# Join with " | "
join_parts() {
  local IFS='|'
  local joined="${*}"
  echo "$joined" | sed 's/|/ | /g'
}

echo "$(join_parts "${parts[@]}")"
