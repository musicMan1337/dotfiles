#!/usr/bin/env bash
# Claude Code statusLine command
# Displays: model | context tokens (usage %) | cwd | git status

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""')

# Shorten home path
short_cwd="${cwd/#$HOME/~}"

# Format token count with commas
format_num() {
  printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# Context info
ctx=""
if [ -n "$input_tokens" ] && [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx="$(format_num "$input_tokens") (${used_int}%)"
elif [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx="${used_int}%"
fi

# Git info (all with GIT_OPTIONAL_LOCKS=0 to avoid blocking)
git_seg=""
if [ -n "$cwd" ]; then
  g="GIT_OPTIONAL_LOCKS=0 git -C $cwd"
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # Staged count
    staged=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    # Unstaged modified count
    modified=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    # Untracked count
    untracked=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    # Stash count
    stash=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
    # Ahead/behind
    upstream=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    ahead=0 behind=0
    if [ -n "$upstream" ]; then
      ahead=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
      behind=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
    fi

    # Build git details
    details=()
    [ "$staged" -gt 0 ] 2>/dev/null && details+=("●${staged}")
    [ "$modified" -gt 0 ] 2>/dev/null && details+=("✚${modified}")
    [ "$untracked" -gt 0 ] 2>/dev/null && details+=("…${untracked}")
    [ "$stash" -gt 0 ] 2>/dev/null && details+=("⚑${stash}")
    [ "$ahead" -gt 0 ] 2>/dev/null && details+=("⇡${ahead}")
    [ "$behind" -gt 0 ] 2>/dev/null && details+=("⇣${behind}")

    git_seg="🔀 ${branch}"
    if [ ${#details[@]} -gt 0 ]; then
      IFS=' '
      git_seg+=" [${details[*]}]"
    fi
  fi
fi

# Build output
parts=()
model_seg="${model}"
[ -n "$effort" ] && model_seg+=" [${effort}]"
parts+=("🤖 ${model_seg}")
[ -n "$ctx" ] && parts+=("🧠 ${ctx}")
parts+=("📂 ${short_cwd}")
[ -n "$git_seg" ] && parts+=("${git_seg}")

# Join with " | "
IFS='|'
output="${parts[*]}"
IFS=' '
output=$(echo "$output" | sed 's/|/ | /g')

echo "$output"
