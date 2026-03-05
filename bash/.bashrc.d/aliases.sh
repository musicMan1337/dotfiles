alias rsource='source ~/.bashrc'

alias test='echo test... testing, 1, 2... test... test, balls... testing, 1... All clear!'
alias ..='cd ..'
alias ...='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
alias exp='explorer.exe .'
alias c.='code .'
alias c='clear'
alias l.='ls -d .* --color=auto'

#~ navigation
alias cdcode='cd ~/code'
alias cddot='cd ~/dotfiles'

#~ open config files
alias cdot='code ~/dotfiles'
alias cbash='code ~/dotfiles/bash/.bashrc'
alias cstar='code ~/dotfiles/bash/.config/starship.toml'
alias czsh='code ~/dotfiles/zsh/.zshrc'
alias cec='code ~/dotfiles/git/.gitconfig'

#~ ngrok
alias ngstatic='ngrok http --url=panda-enhanced-truly.ngrok-free.app $1'

#~ IP, router and port forwarding
alias ports_twilio_on='bash ~/bin/toggle-twilio-port-forwarding.sh on'
alias ports_twilio_off='bash ~/bin/toggle-twilio-port-forwarding.sh off'

alias ssh_router='bash ~/bin/ssh-router.sh'

alias ip_update='curl -s https://ipinfo.io/ip > ~/my-public-ip.txt'
function ip_check() {
  CURRENT_IP=$(curl -s https://ipinfo.io/ip)
  SAVED_IP=$(cat ~/my-public-ip.txt)

  echo "current ip: $CURRENT_IP"
  echo "saved ip: $SAVED_IP"
}

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
