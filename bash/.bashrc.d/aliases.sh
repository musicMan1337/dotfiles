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
alias cdboiler='cd ~/code/boilerplates'
alias cdrw='cd ~/code/react-webpack'
alias cdmpdf='cd /c/mPDF'
alias cdviper='cd /c/Viper'
alias cdsql='cd /c/TAG_SQL'
alias cdint='code-insiders /c/TAG_InterviewQuestions'
alias cdprojects='cd /c/tag-projects'
alias cdcore='cd /c/Core'
#? ...open with IDE
alias ccode='code-insiders ~/code'
alias cboiler='code-insiders ~/code/boilerplates'
alias crw='code-insiders ~/code/react-webpack'

#~ open config files
alias cbash='code-insiders ~/.bashrc'
alias cec='code-insiders ~/.gitconfig'
alias calias='code-insiders ~/.bashrc'

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
