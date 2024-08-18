function colormap() {
  for c in {0..255}; do
    let "d=($c+3)%6"
    printf "\x1b[48;5;%dm  \x1b[49m\x1b[38;5;%dm%03d \x1b[0;37;40m" $c $c $c
    if [ "$d" -eq "0" ]; then echo ""; fi
  done
  echo
}

#~ Snippets_n_Scripts repo update (WSL VERSION)
#? ==> shell aliases <==
alias wsl_zAliases='cp ~/.oh-my-zsh/custom/aliases.zsh .'
alias wsl_zGitconfig='cp ~/.gitconfig .'
alias wsl_bAliases='cp /mnt/c/Users/admin/.bashrc .'
alias wsl_bGitconfig='cp /mnt/c/Users/admin/.gitconfig .'
alias wsl_bPurelinerc='cp /mnt/c/Users/admin/.pureline.conf .'
alias wsl_bPureline='cp -r /mnt/c/Users/admin/pureline .'
#? ==> shell .rc files <==
alias wsl_zBashrc='cp ~/.bashrc .'
alias wsl_zZshrc='cp ~/.zshrc .'
alias wsl_zP10k='cp ~/.p10k.zsh .'
#? ==> hereDocs <==
alias wsl_hDocs='cp -r /mnt/c/Users/admin/hereDocs .'
#? ==> windows terminal settings <==
alias wsl_wtsettings='cp /mnt/c/Users/admin/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json .'
#? ==> target repo <==
alias wsl_cdzScripts='cd /mnt/c/Users/admin/CODE/dot_files/ubuntu_zsh_scripts'
alias wsl_cdbScripts='cd /mnt/c/Users/admin/CODE/dot_files/win10_bash_scripts'
alias wsl_cdShellsrc='cd /mnt/c/Users/admin/CODE/dot_files/shellrc_Files'
#! ==> mega updater <==
snsupdate_wsl() {
  wsl_cdzScripts && wsl_zAliases
  wsl_zGitconfig
  wsl_cdbScripts && wsl_bAliases
  wsl_bGitconfig
  wsl_bPurelinerc
  wsl_bPureline
  wsl_cdShellsrc && wsl_zBashrc
  wsl_zZshrc
  wsl_zP10k
  ..
  wsl_wtsettings && wsl_hDocs && git add . && git commit -m \'save\' && git push
}

#~ Snippets_n_Scripts repo update (WINDOWS VERSION)
#? ==> shell aliases <==
alias win_bAliases='cp ~/.bashrc .'
alias win_bGitconfig='cp ~/.gitconfig .'
alias win_bPurelinerc='cp ~/.pureline.conf .'
alias win_bPureline='cp -r ~/pureline .'
#? ==> hereDocs <==
alias win_hDocs='cp -r ~/hereDocs .'
#? ==> windows terminal settings <==
alias win_wtsettings='cp ~/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json .'
#? ==> target repo <==
alias win_cdzScripts='cd ~/CODE/dot_files/ubuntu_zsh_scripts'
alias win_cdbScripts='cd ~/CODE/dot_files/win10_bash_scripts'
alias win_cdShellsrc='cd ~/CODE/dot_files/shellrc_Files'
#! ==> mega updater <==
snsupdate_win() {
  win_cdbScripts && win_bAliases
  win_bGitconfig
  win_bPurelinerc
  win_bPureline
  ..
  win_wtsettings && win_hDocs && git add . && git commit -m \'save\' && git push
}
