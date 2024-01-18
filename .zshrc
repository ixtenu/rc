# Generic shell initialization (not specific to zsh)
[ -f "$HOME/.shrc" ] && source "$HOME/.shrc"

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
