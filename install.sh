#!/usr/bin/env sh
set -eu

scriptdir="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$scriptdir"

installfile() {
	lnvopt='-v'
	[ "$(uname)" = "OpenBSD" ] && lnvopt=''

	dst="$1"
	dir="$(dirname "$dst")"
	src="$(basename "$dst")"
	[ $# -gt 1 ] && src="$2"
	src="$scriptdir"/"$src"
	if [ ! -r "$src" ]; then
		echo "error: $src not an existing readable file" 1>&2
		exit 1
	fi
	mkdir -p "$dir"
	if [ -L "$dst" ]; then
		# Don't rewrite the symbolic link unless it's changed.
		[ -e "$dst" ] && target="$(readlink -f "$dst")" || target=
		if [ "$target" != "$src" ]; then
			ln -snf $lnvopt "$src" "$dst"
		fi
	elif [ ! -e "$dst" ]; then
		ln -s $lnvopt "$src" "$dst"
	else
		echo "warning: $dst exists and is not a symbolic link, leaving it" 1>&2
	fi
}

installcmd() {
	if command -v "$1" >/dev/null 2>&1; then
		shift
		installfile $@
	fi
}

installcmd X "$HOME/.Xresources"
installcmd alacritty "$HOME/.config/alacritty/alacritty.yml"
installcmd alacritty "$HOME/.config/alacritty/alacritty.toml"
installcmd cwm "$HOME/.cwmrc"
installcmd jwm "$HOME/.jwmrc"
installcmd emacs "$HOME/.emacs.d"
installcmd jmacs "$HOME/.jmacsrc"
installcmd joe "$HOME/.joerc"
installcmd mg "$HOME/.mg"
installcmd nano "$HOME/.config/nano/nanorc"
installcmd nvim "$HOME/.config/nvim/ginit.vim" .gvimrc
installcmd nvim "$HOME/.config/nvim/init.vim" .vimrc
installcmd tmux "$HOME/.tmux.conf"
installcmd vim "$HOME/.gvimrc"
installcmd vim "$HOME/.vimrc"
installcmd sh "$HOME/.shrc"
installcmd zsh "$HOME/.zshrc"
installcmd ksh "$HOME/.kshrc"

if command -v sam >/dev/null 2>&1; then
	# .samrc is for deadpixi/sam; don't install it for 9fans/plan9port sam
	if [ -x /usr/local/bin/sam ]; then
		installfile "$HOME/.samrc"
	fi
fi
if command -v vis >/dev/null 2>&1 || command -v vise >/dev/null 2>&1; then
	# vis on *BSD is an unrelated program
	if [ "$(uname)" = "Linux" -o "$(which vis)" != "/usr/bin/vis" ]; then
		installfile "$HOME/.config/vis/visrc.lua"
	fi
fi

cp_if_needed() {
	if ! cmp -s "$1" "$2"; then
		cp -v "$1" "$2"
	fi
}

# If running from within the Windows Subsystem for Linux...
if [ -d /mnt/c/Windows/System32 ]; then
	# Windows username might differ from WSL username
	WINUSER="$(powershell.exe '$env:UserName' | sed 's/\r//')"
	WINHOME="/mnt/c/Users/$WINUSER"

	# Windows Neovim
	if [ -d "$WINHOME/AppData/Local/nvim" ]; then
		cp_if_needed .vimrc "$WINHOME/AppData/Local/nvim/init.vim"
		cp_if_needed .gvimrc "$WINHOME/AppData/Local/nvim/ginit.vim"
	fi
	# Windows Vim
	if [ -f "$WINHOME/_vimrc" ]; then
		cp_if_needed .vimrc "$WINHOME/_vimrc"
		cp_if_needed .gvimrc "$WINHOME/_gvimrc"
	fi
	# Git Bash Vim
	if [ -f "$WINHOME/.vimrc" ]; then
		cp_if_needed .vimrc "$WINHOME/.vimrc"
	fi
	# GNU Emacs
	if [ -d "$WINHOME/.emacs.d" ]; then
		find .emacs.d -type f |
		while IFS= read -r fn; do
			cp_if_needed "$fn" "$WINHOME/$fn"
		done
	fi
fi
