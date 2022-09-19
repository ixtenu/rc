#!/usr/bin/env sh
set -eu

scriptdir="$(cd -- "$(dirname "$0")" 2>&1 >/dev/null && pwd -P)"
cd "$scriptdir"

installfile() {
	lnvopt='-v'
	[ "$(uname)" = "OpenBSD" ] && lnvopt=''

	dst="$1"
	dir="$(dirname "$dst")"
	src="$(basename "$dst")"
	[ $# -gt 1 ] && src="$2"
	src="$scriptdir"/"$src"
	if [ ! -f "$src" -o ! -r "$src" ]; then
		echo "error: $src not an existing readable regular file" 2>&1
		exit 1
	fi
	mkdir -p "$dir"
	if [ -e "$dst" ]; then
		if [ -L "$dst" ]; then
			ln -sf $lnvopt "$src" "$dst"
		else
			echo "warning: $dst exists and is not a symbolic link, leaving it" 2>&1
		fi
	else
		ln -s $lnvopt "$src" "$dst"
	fi
}

if command -v X 2>&1 >/dev/null; then
	installfile "$HOME/.Xresources"
fi
if command -v cwm 2>&1 >/dev/null; then
	installfile "$HOME/.cwmrc"
fi
if command -v joe 2>&1 >/dev/null; then
	installfile "$HOME/.joerc"
	installfile "$HOME/.jmacsrc"
fi
if command -v mg 2>&1 >/dev/null; then
	installfile "$HOME/.mg"
fi
if command -v sam 2>&1 >/dev/null; then
	# .samrc is for deadpixi/sam; don't install it for 9fans/plan9port sam
	if [ -x /usr/local/bin/sam ]; then
		installfile "$HOME/.samrc"
	fi
fi
if command -v zsh 2>&1 >/dev/null; then
	installfile "$HOME/.zshrc"
fi

if command -v vim 2>&1 >/dev/null; then
	installfile "$HOME/.vimrc"
fi
if command -v nvim 2>&1 >/dev/null; then
	installfile "$HOME/.config/nvim/init.vim" .vimrc
fi

# If running from within the Windows Subsystem for Linux...
if [ -d /mnt/c/Windows/System32 ]; then
	# Windows username might differ from WSL username
	WINUSER="$(powershell.exe '$env:UserName' | sed 's/\r//')"
	WINHOME="/mnt/c/Users/$WINUSER"

	# Windows Neovim
	if [ -d "$WINHOME/AppData/Local/nvim" ]; then
		cp -v .vimrc "$WINHOME/AppData/Local/nvim/init.vim"
	fi
	# Windows Vim
	if [ -f "$WINHOME/_vimrc" ]; then
		cp -v .vimrc "$WINHOME/_vimrc"
	fi
	# Git Bash Vim
	if [ -f "$WINHOME/.vimrc" ]; then
		cp -v .vimrc "$WINHOME/.vimrc"
	fi
fi
