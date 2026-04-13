source ~/.bashrc.d/aliases.sh

alias rsource='source ~/.zshrc && source ~/.zprofile'

# ls/eza
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -a'
fi
