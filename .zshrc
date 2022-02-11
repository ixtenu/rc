HISTFILE=~/.histfile
HISTSIZE=32768
SAVEHIST=32768

bindkey -e

# Customize the prompt.  Based on the "walters" theme but with a simpler PS1.
autoload -Uz promptinit && promptinit
prompt_custom_setup() {
	PS1="%# "
	if [[ "$TERM" != "dumb" ]]; then
		RPS1="%F{${1:-green}}%~%f"
	fi
	prompt_opts=(cr percent)
}
prompt_themes+=(custom)
prompt custom

setopt interactivecomments
setopt autocd notify
unsetopt beep

export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/go/bin

if command -v godit >/dev/null; then
	alias em='godit'
elif command -v joe >/dev/null; then
	alias em='jmacs'
elif command -v mg >/dev/null; then
	alias em='mg'
fi

export EDITOR=em
export VISUAL=$EDITOR

# Modified commands
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'

# New commands
alias hist='cat ~/.histfile | grep' # requires an argument

# Privileged access
if (( UID != 0 )); then
	alias root='sudo -i'
	if [ "$(uname)" = "Linux" ]; then
		alias reboot='sudo systemctl reboot'
		alias poweroff='sudo systemctl poweroff'
	fi
fi

# ls
alias ls='ls -hF --color=auto'
alias lr='ls -R' # recursive ls
alias ll='ls -l'
alias la='ll -A'
if [ "$(uname)" = "Linux" ]; then
	alias lx='ll -BX'
fi
alias lz='ll -rS' # sort by size
alias lt='ll -rt' # sort by date

# Safety features
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'
alias ln='ln -i'
if [ "$(uname)" = "Linux" ]; then
	alias chown='chown --preserve-root'
	alias chmod='chmod --preserve-root'
	alias chgrp='chgrp --preserve-root'
fi

# Image viewing
if command -v nsxiv >/dev/null; then
	alias img='nsxiv'
elif command -v sxiv >/dev/null; then
	alias img='sxiv'
fi

# Screen capturing from terminal.
if command -v maim >/dev/null; then
	alias screencap_desktop='maim'
	alias screencap_window='maim -st 9999999'
	alias screencap_select='maim -s'
	if command -v xclip >/dev/null; then
		alias clip_png='xclip -selection clipboard -t image/png'
	fi
fi

# GNU Emacs
if command -v emacs >/dev/null; then
	alias ge='emacs -nw'
	alias gec='emacsclient -n'
fi

# zsh plugin directory varies by system
zshplugdir=""
if [ -d "/usr/share/zsh/plugins/" ]; then
	zshplugdir="/usr/share/zsh/plugins/"
elif [ -d "/usr/share/zsh-autosuggestions" ]; then
	zshplugdir="/usr/share"
elif [ -d "/usr/local/share/zsh-autosuggestions" ]; then
	zshplugdir="/usr/local/share"
fi

# Source plugins
if [ "$zshplugdir" != "" ]; then
	if [ -f "$zshplugdir"/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
		source "$zshplugdir"/zsh-autosuggestions/zsh-autosuggestions.zsh
	fi
	# zsh-syntax-highlighting docs says it must be sourced at the very end
	if [ -f "$zshplugdir"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
		source "$zshplugdir"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	fi
fi
