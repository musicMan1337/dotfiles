# claude-usage: live view of Claude Code subscription usage (the `/usage` screen)
#
# Data source: the same undocumented OAuth endpoint Claude Code's /usage reads,
#   GET https://api.anthropic.com/api/oauth/usage
# Auth: OAuth access token pulled from the macOS Keychain item "Claude Code-credentials".
# Note: the endpoint is reverse-engineered / unofficial; schema may change. It is
#   meant to be fetched on demand, so it rate-limits (429) under tight polling —
#   hence the conservative default interval and the backoff below.
#
# Usage:
#   claude-usage [interval]   live, refreshing every <interval> seconds (default 60)
#   claude-usage --once       print a single snapshot and exit
#   cu                        short alias

_cu_token() {
  security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
    | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
}

_cu_dur() { # seconds -> "Xd Yh" / "Xh Ym" / "Xm"
  local s=$1
  if [ "$s" -lt 0 ] 2>/dev/null; then printf 'now'; return; fi
  local d=$(( s/86400 )) h=$(( (s%86400)/3600 )) m=$(( (s%3600)/60 ))
  if   (( d > 0 )); then printf '%dd %dh' "$d" "$h"
  elif (( h > 0 )); then printf '%dh %dm' "$h" "$m"
  else                   printf '%dm' "$m"
  fi
}

_cu_bar() { # percent severity -> colored block bar
  local pct=$1 sev=$2 width=24 color i filled bar=''
  (( pct > 100 )) && pct=100
  (( pct < 0 ))   && pct=0
  filled=$(( pct*width/100 ))
  case "$sev" in
    critical) color=$'\033[31m' ;;
    warning)  color=$'\033[33m' ;;
    *)        color=$'\033[32m' ;;
  esac
  [ -t 1 ] || color=''
  for (( i=0; i<width; i++ )); do
    if (( i < filled )); then bar+='█'; else bar+='░'; fi
  done
  printf '%s%s%s' "$color" "$bar" "${color:+$'\033[0m'}"
}

_cu_render() { # json [when-label]
  local json="$1" when="$2"
  local DIM=$'\033[2m' BLD=$'\033[1m' RST=$'\033[0m'
  [ -t 1 ] || { DIM=''; BLD=''; RST=''; }
  [ -n "$when" ] || when="$(date '+%H:%M:%S')"

  printf '%sClaude usage%s  %s%s%s\n\n' "$BLD" "$RST" "$DIM" "$when" "$RST"

  local rows
  rows="$(printf '%s' "$json" | jq -r '
    .limits[]?
    | [ .kind,
        (.scope.model.display_name // ""),
        ((.percent // 0) | floor | tostring),
        (.severity // "normal"),
        ( if .resets_at
          then ((.resets_at[0:19] + "Z" | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) - now | floor | tostring)
          else "-1" end ),
        ((.is_active // false) | tostring)
      ] | join("|")' 2>/dev/null)"

  if [ -z "$rows" ]; then printf '  %s(no limit data)%s\n' "$DIM" "$RST"; return; fi

  local kind model pct sev secs active label star
  while IFS='|' read -r kind model pct sev secs active; do
    [ -z "$kind" ] && continue
    case "$kind" in
      session)       label='Session (5h)' ;;
      weekly_all)    label='Weekly (all)' ;;
      weekly_scoped) label="Weekly (${model:-scoped})" ;;
      *)             label="$kind" ;;
    esac
    star=' '; [ "$active" = 'true' ] && star='*'
    printf '  %s %-16s %s %3d%%  %sresets %s%s\n' \
      "$star" "$label" "$(_cu_bar "$pct" "$sev")" "$pct" "$DIM" "$(_cu_dur "$secs")" "$RST"
  done <<< "$rows"
}

claude-usage() {
  local interval=60 once=0 a
  for a in "$@"; do
    case "$a" in
      -h|--help)
        printf 'claude-usage [interval]   live view, refresh every <interval>s (default 60)\n'
        printf 'claude-usage --once       single snapshot\n'
        return 0 ;;
      --once|once) once=1 ;;
      *) [[ "$a" =~ ^[0-9]+$ ]] && interval="$a" ;;
    esac
  done
  (( interval < 1 )) && interval=1

  command -v jq   >/dev/null 2>&1 || { echo 'claude-usage: requires jq'   >&2; return 1; }
  command -v curl >/dev/null 2>&1 || { echo 'claude-usage: requires curl' >&2; return 1; }

  local ver; ver="$(claude --version 2>/dev/null | awk '{print $1}')"; [ -n "$ver" ] || ver='2.0.0'
  local DIM=$'\033[2m' YEL=$'\033[33m' RST=$'\033[0m'
  [ -t 1 ] || { DIM=''; YEL=''; RST=''; }

  local token; token="$(_cu_token)"
  if [ -z "$token" ]; then
    echo 'claude-usage: no OAuth token in Keychain (sign in via Claude Code first)' >&2
    return 1
  fi

  local sep=$'\n__CU__\n'            # write-out delimiter between body and metadata
  local resp meta code retry body
  local last_good='' last_ts=''      # cache of the most recent successful render
  local backoff=0 sleep_for note

  while :; do
    # -w order matters: retry-after first, http_code LAST — the code is always
    # present, so making it the final field survives $()'s trailing-newline strip
    # even when the Retry-After header is absent (which would otherwise collapse
    # the metadata to a single ambiguous token).
    resp="$(curl -s -m 10 \
      -w "${sep}%header{retry-after}"$'\n'"%{http_code}" \
      https://api.anthropic.com/api/oauth/usage \
      -H "Authorization: Bearer $token" \
      -H 'anthropic-beta: oauth-2025-04-20' \
      -H "User-Agent: claude-code/${ver}" \
      -H 'Content-Type: application/json' 2>/dev/null)"
    if [[ "$resp" == *"$sep"* ]]; then
      meta="${resp##*$sep}"          # "<retry-after>\n<code>"
      body="${resp%$sep*}"
      retry="${meta%%$'\n'*}"
      code="${meta##*$'\n'}"
    else
      body=''; retry=''; code=000    # no delimiter -> curl never got a response
    fi

    sleep_for=$interval
    note=''

    case "$code" in
      200)
        backoff=0
        last_good="$body"; last_ts="$(date '+%H:%M:%S')"
        (( once )) || printf '\033[H\033[J'
        _cu_render "$body" "$last_ts"
        ;;
      401|403)
        token="$(_cu_token)"          # pick up a token another Claude process refreshed
        note="auth ${code} — run any Claude command to refresh"
        (( once )) || printf '\033[H\033[J'
        [ -n "$last_good" ] && _cu_render "$last_good" "${last_ts} (stale)"
        ;;
      429|5[0-9][0-9]|000)
        if [ "$code" = 429 ] && [[ "$retry" =~ ^[0-9]+$ ]]; then
          sleep_for=$retry            # honor Retry-After
        else
          (( backoff = backoff==0 ? interval : backoff*2 ))
          (( backoff > 300 )) && backoff=300
          sleep_for=$backoff          # exponential fallback, capped at 5m
        fi
        case "$code" in
          429) note="rate-limited — retrying in ${sleep_for}s" ;;
          000) note="network unreachable — retrying in ${sleep_for}s" ;;
          *)   note="service unavailable (${code}) — retrying in ${sleep_for}s" ;;
        esac
        (( once )) || printf '\033[H\033[J'
        [ -n "$last_good" ] && _cu_render "$last_good" "${last_ts} (stale)"
        ;;
      *)
        note="HTTP ${code}"
        (( once )) || printf '\033[H\033[J'
        [ -n "$last_good" ] && _cu_render "$last_good" "${last_ts} (stale)"
        ;;
    esac

    if (( once )); then
      [ -n "$note" ] && printf '%s%s%s\n' "$YEL" "$note" "$RST"
      break
    fi

    if [ -n "$note" ]; then
      printf '\n%s⚠ %s · Ctrl-C to quit%s\n' "$YEL" "$note" "$RST"
    else
      printf '\n%s↻ %ss · Ctrl-C to quit%s\n' "$DIM" "$interval" "$RST"
    fi
    sleep "$sleep_for"
  done
  return 0
}

alias cu='claude-usage'
