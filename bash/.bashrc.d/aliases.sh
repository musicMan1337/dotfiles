alias test='echo test... testing, 1, 2... test... test, balls... testing, 1... All clear!'
alias ..='cd ..'
alias ...='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
alias exp='explorer.exe .'
alias c.='code-insiders .'
alias c='clear'
alias l.='ls -d .* --color=auto'

#~ navigation
alias cdcode='cd ~/code'

#~ open config files
alias cbash='code-insiders ~/dotfiles/bash/.bashrc'
alias cec='code-insiders ~/dotfiles/git/.gitconfig'

#~ tput (fancy stdout)
#? Font Style
BOLD=$(tput bold)
UNDERL_BEG=$(tput smul)
UNDERL_END=$(tput rmul)
RESET_ATTRS=$(tput sgr0)
#? Font Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PURPLE=$(tput setaf 5)
CYAN=$(tput setaf 6)
GRAY=$(tput setaf 7)
#? Background Colors
RED_B=$(tput setab 1)
GREEN_B=$(tput setab 2)
YELLOW_B=$(tput setab 3)
BLUE_B=$(tput setab 4)
PURPLE_B=$(tput setab 5)
CYAN_B=$(tput setab 6)
GRAY_B=$(tput setab 7)
