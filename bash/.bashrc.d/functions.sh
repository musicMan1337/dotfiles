# rename-tab: set the current terminal tab title (Warp honors OSC 0 when
# WARP_DISABLE_AUTO_TITLE=true, set in zsh exports.sh).
# Interactive shells write to /dev/tty. From a detached child (e.g. Claude
# Code's Bash tool, which has no controlling tty) it walks up the process tree
# to the first ancestor on a real pty and writes the OSC there.
# Usage: rename-tab my-feature   (keep it 1-3 words)
function rename-tab() {
  local title="$*" t pid
  if { : >/dev/tty; } 2>/dev/null; then
    printf '\033]0;%s\007' "$title" >/dev/tty
    return 0
  fi
  pid=${PPID:-1}
  while [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ]; do
    t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    case "$t" in
      ttys*|tty[0-9]*)
        printf '\033]0;%s\007' "$title" >"/dev/$t" 2>/dev/null && return 0 ;;
    esac
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
  return 1
}

function colormap() {
  for c in {0..255}; do
    let "d=($c+3)%6"
    printf "\x1b[48;5;%dm  \x1b[49m\x1b[38;5;%dm%03d \x1b[0;37;40m" $c $c $c
    if [ "$d" -eq "0" ]; then echo ""; fi
  done
  echo
}
