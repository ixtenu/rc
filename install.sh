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
		echo "error: $src not an existing readable file" 2>&1
		exit 1
	fi
	mkdir -p "$dir"
	if [ -e "$dst" ]; then
		if [ -L "$dst" ]; then
			ln -snf $lnvopt "$src" "$dst"
		else
			echo "warning: $dst exists and is not a symbolic link, leaving it" 2>&1
		fi
	else
		ln -s $lnvopt "$src" "$dst"
	fi
}

if command -v X >/dev/null 2>&1; then
	installfile "$HOME/.Xresources"
fi
if command -v cwm >/dev/null 2>&1; then
	installfile "$HOME/.cwmrc"
fi
if command -v emacs >/dev/null 2>&1; then
	installfile "$HOME/.emacs.d"
fi
if command -v joe >/dev/null 2>&1; then
	installfile "$HOME/.joerc"
	installfile "$HOME/.jmacsrc"
fi
if command -v nano >/dev/null 2>&1; then
	installfile "$HOME/.config/nano/nanorc"
fi
if command -v mg >/dev/null 2>&1; then
	installfile "$HOME/.mg"
fi
if command -v sam >/dev/null 2>&1; then
	# .samrc is for deadpixi/sam; don't install it for 9fans/plan9port sam
	if [ -x /usr/local/bin/sam ]; then
		installfile "$HOME/.samrc"
	fi
fi
if command -v vis >/dev/null 2>&1 || command -v vise >/dev/null 2>&1; then
	# vis on *BSD is an unrelated program
	if [ "$(uname)" = "Linux" -o "$(which vis)" != "/usr/bin/vis" ]; then
		installfile "$HOME/.config/vis/visrc.lua" visrc.lua
	fi
fi
if command -v tmux >/dev/null 2>&1; then
	installfile "$HOME/.tmux.conf"
fi
if command -v zsh >/dev/null 2>&1; then
	installfile "$HOME/.zshrc"
fi

if command -v vim >/dev/null 2>&1; then
	installfile "$HOME/.vimrc"
	installfile "$HOME/.gvimrc"
fi
if command -v nvim >/dev/null 2>&1; then
	installfile "$HOME/.config/nvim/init.vim" .vimrc
	installfile "$HOME/.config/nvim/ginit.vim" .gvimrc
fi

# If running from within the Windows Subsystem for Linux...
if [ -d /mnt/c/Windows/System32 ]; then
	# Windows username might differ from WSL username
	WINUSER="$(powershell.exe '$env:UserName' | sed 's/\r//')"
	WINHOME="/mnt/c/Users/$WINUSER"

	# Windows Neovim
	if [ -d "$WINHOME/AppData/Local/nvim" ]; then
		cp -v .vimrc "$WINHOME/AppData/Local/nvim/init.vim"
		cp -v .gvimrc "$WINHOME/AppData/Local/nvim/ginit.vim"
	fi
	# Windows Vim
	if [ -f "$WINHOME/_vimrc" ]; then
		cp -v .vimrc "$WINHOME/_vimrc"
		cp -v .gvimrc "$WINHOME/_gvimrc"
	fi
	# Git Bash Vim
	if [ -f "$WINHOME/.vimrc" ]; then
		cp -v .vimrc "$WINHOME/.vimrc"
	fi
fi
