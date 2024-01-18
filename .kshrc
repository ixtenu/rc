[ -f "$HOME/.shrc" ] && . "$HOME/.shrc"
[ $(id -u) -eq 0 ] && PS1="# " || PS1="% "

