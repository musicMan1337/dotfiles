function colormap() {
  for c in {0..255}; do
    let "d=($c+3)%6"
    printf "\x1b[48;5;%dm  \x1b[49m\x1b[38;5;%dm%03d \x1b[0;37;40m" $c $c $c
    if [ "$d" -eq "0" ]; then echo ""; fi
  done
  echo
}
