#~ Source all .sh files in .bashrc.d
if [ -d ~/.bashrc.d/ ]; then
  for file in ~/.bashrc.d/*.sh; do
    [ -r "$file" ] && source "$file"
  done
  unset file
fi

#~ fnm setup
eval "$(fnm env --use-on-cd --shell bash)"

#~ Starship PS1 setup (~/.config/starship.toml)
eval "$(starship init bash)"

case $OSTYPE in
*kali*) ICON=" " ;;
*darwin*) ICON="darwin " ;;
*arch*) ICON=" " ;;
*linux*) ICON=" " ;;
*cygwin*) ICON="cygwin " ;;
*debian*) ICON=" " ;;
*ubuntu*) ICON=" " ;;
*msys*) ICON="󰖳 " ;;
*) ICON="" ;;
esac

export STARSHIP_DISTRO=$ICON

#~ Initial Load Message (interactive shells only)
#~ Printing to stdout while a non-interactive shell sources this file corrupts
#~ environment snapshots (e.g. Claude Code's) — the banner bleeds into $PATH and
#~ breaks child `node`/`cmd`/`powershell` resolution. Guard it behind $- == *i*.
if [[ $- == *i* ]]; then
  eval 'bash ~/hereDocs/asciiArt/loadMessage.txt'
fi

#~ Base PS1 (fallback)
parse_git_branch() { git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'; }

PS1="\[\033[38;5;9m\]\u\[$(tput sgr0)\]\[\033[38;5;10m\][\[$(tput sgr0)\]\[\033[38;5;33m\]$MSYSTEM\[\033[38;5;10m\]]\[\033[38;5;10m\]:\[$(tput sgr0)\] \[$(tput sgr0)\]\[\033[38;5;3m\]\W\[\033[38;5;9m\]\$(parse_git_branch)\[$(tput sgr0)\] $ "

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/derek/.lmstudio/bin"
# End of LM Studio CLI section

alias claude-up='npm update -g @anthropic-ai/claude-code'
alias claude-d='claude --dangerously-skip-permissions'
