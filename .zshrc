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

iscmd() {
	command -v "$1" >/dev/null 2>&1
}

# Add directory to PATH if it exists and isn't already in PATH.
addtopath() {
	[ ! -d $1 ] && return
	echo "$PATH" | grep ":$1$" >/dev/null && return
	echo "$PATH" | grep ":$1:" >/dev/null && return
	export PATH=$PATH:$1
}

addtopath $HOME/bin
addtopath $HOME/go/bin
addtopath $HOME/.cargo/bin

if [ -d /usr/local/plan9 ]; then
	export PLAN9=/usr/local/plan9
elif [ -d $HOME/plan9 ]; then
	export PLAN9=$HOME/plan9
fi
[ ! -z "$PLAN9" ] && addtopath $PLAN9/bin

editors=(nano mg jmacs godit nvim vim vi)
for e in $editors; do
	if iscmd $e; then
		export EDITOR=$e
		export VISUAL=$e
		break
	fi
done

# If running in WSL...
if [ -d /mnt/c/Windows ]; then
	# Only do this if VcXsrv is installed (assuming its default location)
	# because, if WSLg is being used instead, it needs the default value
	# of DISPLAY
	if [ -e '/mnt/c/Program Files/VcXsrv/vcxsrv.exe' ]; then
		# Set DISPLAY for VcXsrv
		export DISPLAY=$(/sbin/ip route | awk '/default/ { print $3 }'):0
	fi
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
alias ll='ls -l' # detailed ls
alias la='ll -A' # detailed ls, including dotfiles
if [ "$(uname)" = "Linux" ]; then
	alias lx='ll -BX' # sort by extension
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
if iscmd nsxiv; then
	alias img='nsxiv'
elif iscmd sxiv; then
	alias img='sxiv'
fi

# Screen capturing from terminal.
if iscmd maim; then
	alias screencap_desktop='maim'
	alias screencap_window='maim -st 9999999'
	alias screencap_select='maim -s'
	if iscmd xclip; then
		alias clip_png='xclip -selection clipboard -t image/png'
	fi
fi

# GNU Emacs
if iscmd emacs; then
	alias ge='emacs -nw'
	alias gec='emacsclient -n'
fi

if iscmd nvim; then
	alias vi='nvim'
	alias vim='nvim'
elif iscmd vim; then
	alias vi='vim'
fi

if iscmd nano && ! iscmd na; then
	alias na='nano'
fi

# Alias helix to hx on systems which install it as helix
if iscmd helix && ! iscmd hx; then
	alias hx='helix'
fi

# Debian/Ubuntu renamed fd to fdfind due to a naming conflict.
if iscmd fdfind && ! iscmd fd; then
	alias fd='fdfind'
fi

# kitty's SSH wrapper.
if iscmd kitty; then
	alias kssh='kitty +kitten ssh'
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
if [ ! -z "$zshplugdir" ]; then
	if [ -f "$zshplugdir"/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
		source "$zshplugdir"/zsh-autosuggestions/zsh-autosuggestions.zsh
	fi
	# zsh-syntax-highlighting docs says it must be sourced at the very end
	if [ -f "$zshplugdir"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
		source "$zshplugdir"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	fi
fi
