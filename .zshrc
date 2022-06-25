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

if [ -d /usr/local/plan9 ]; then
	export PLAN9=/usr/local/plan9
	export PATH=$PATH:$PLAN9/bin
fi

if command -v godit >/dev/null; then
	export EDITOR=godit
elif command -v joe >/dev/null; then
	export EDITOR=jmacs
elif command -v mg >/dev/null; then
	export EDITOR=mg
fi

export VISUAL=$EDITOR
alias em=$EDITOR

# If running in WSL...
if [ -d /mnt/c/Windows ]; then
	# Set DISPLAY for VcXsrv
	export DISPLAY=$(/sbin/ip route | awk '/default/ { print $3 }'):0
fi

# Modified commands
if [ "$(uname)" != "OpenBSD" ]; then
	alias grep='grep --color=auto'
fi
alias df='df -h'
alias du='du -h'

# New commands
alias hist='cat ~/.histfile | grep' # requires an argument

mkcd() {
	if [ $# -eq 0 ]; then
		echo "$0: missing operand" 1>&2
		echo "usage: $0 directory" 1>&2
		echo "mkdir and chdir into the given directory." 1>&2
		return 1
	fi
	mkdir -p "$1"
	cd "$1"
}

upcd() {
	dir=""
	for i in $(seq 1 $1); do
		dir="../$dir"
	done
	[ -z "$dir" ] && dir="$PWD"
	cd "$dir"
}

# Privileged access
if (( UID != 0 )); then
	alias root='sudo -i'
	if [ "$(uname)" = "Linux" ]; then
		alias reboot='sudo systemctl reboot'
		alias poweroff='sudo systemctl poweroff'
	fi
fi

# ls
if [ "$(uname)" = "OpenBSD" ]; then
	alias ls='ls -hF'
else
	alias ls='ls -hF --color=auto'
fi
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
if [ "$(uname)" = "OpenBSD" ]; then
	alias rm='rm -i'
else
	alias rm='rm -I'
fi
if [ "$(uname)" != "OpenBSD" ]; then
	alias ln='ln -i'
fi
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

# On Ubuntu, zsh doesn't source the necessary files for snap applications, and
# manual sourcing from here doesn't seem to solve the issue.  As a workaround,
# create symlinks for the *.desktop files.
if [ -d /var/lib/snapd/desktop/applications ]; then
	for i in $(find /var/lib/snapd/desktop/applications -name "*.desktop"); do
		if [ ! -f ~/.local/share/applications/${i##*/} ]; then
			mkdir -p ~/.local/share/applications
			ln -s /var/lib/snapd/desktop/applications/${i##*/} ~/.local/share/applications/${i##*/}
		fi
	done
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
