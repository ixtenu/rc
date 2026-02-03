#!/usr/bin/env sh
set -eu

scriptdir="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$scriptdir"

symlinks_supported='yes'
if ! command -v ln >/dev/null 2>&1 || \
   ! ln -sf "$(basename "$0")" test_lnk || \
   [ ! -L test_lnk ]; then
	symlinks_supported='no'
	echo "warning: symbolic links aren't supported in this environment" 1>&2
fi
rm -f test_lnk

installfile() {
	[ "$symlinks_supported" = "no" ] && return

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
installcmd alacritty "$HOME/.config/alacritty/alacritty.toml"
installcmd cwm "$HOME/.cwmrc"
installcmd jwm "$HOME/.jwmrc"
installcmd emacs "$HOME/.emacs.d"
installcmd ex "$HOME/.nexrc"
installcmd jmacs "$HOME/.jmacsrc"
installcmd joe "$HOME/.joerc"
installcmd mg "$HOME/.mg"
installcmd nano "$HOME/.config/nano/nanorc"
installcmd dte "$HOME/.dte/rc" dterc
installcmd nex "$HOME/.nexrc"
installcmd nvim "$HOME/.config/nvim/ginit.vim" .gvimrc
installcmd nvim "$HOME/.config/nvim/init.vim" .vimrc
installcmd rofi "$HOME/.config/rofi/config.rasi"
installcmd textadept "$HOME/.textadept"
installcmd tmux "$HOME/.tmux.conf"
installcmd vim "$HOME/.gvimrc"
installcmd vim "$HOME/.vimrc"
installcmd sh "$HOME/.shrc"
installcmd zsh "$HOME/.zshrc"
installcmd ksh "$HOME/.kshrc"
installcmd nu "$HOME/.config/nushell/config.nu"

if command -v sam >/dev/null 2>&1; then
	# .samrc is for japanoise/sam; don't install it for 9fans/plan9port sam
	#
	# On NixOS, plan9port only puts the 9 script in the PATH; so if sam is
	# in the path, assume it's japanoise/sam.
	#
	# For other Linux/*BSD, plan9port is typically at /usr/local/plan9;
	# assume japanoise/sam only if /usr/local/bin/sam exists.
	if [ -d /etc/nixos ] || [ -x /usr/local/bin/sam ]; then
		installfile "$HOME/.config/sam/samrc" .samrc
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

cpr_if_needed() {
	if [ -d "$1" ]; then
		mkdir -pv "$2"
		for de in "$1"/*; do
			cpr_if_needed "$1"/"$(basename $de)" "$2"/"$(basename $de)"
		done
	elif [ -e "$1" ]; then
		cp_if_needed "$1" "$2"
	fi
}

# If running from within the Windows Subsystem for Linux (which mounts C:\ at
# /mnt/c) or Git Bash for Windows (which mounts C:\ at /c)...
cdrive=
[ -d /mnt/c/Windows/System32 ] && cdrive='/mnt/c'
[ -d /c/Windows/System32 ] && cdrive='/c'
if [ -n "$cdrive" ] && command -v powershell.exe >/dev/null 2>&1; then
	# Windows username might differ from WSL username
	winuser="$(powershell.exe '$env:UserName' | sed 's/\r//')"
	winhome="$cdrive/Users/$winuser"

	# Windows Neovim
	if [ -d "$winhome/AppData/Local/nvim" ]; then
		cp_if_needed .vimrc "$winhome/AppData/Local/nvim/init.vim"
		cp_if_needed .gvimrc "$winhome/AppData/Local/nvim/ginit.vim"
	fi
	# Windows Vim
	if [ -f "$winhome/_vimrc" ]; then
		cp_if_needed .vimrc "$winhome/_vimrc"
		cp_if_needed .gvimrc "$winhome/_gvimrc"
	fi
	# Git Bash Vim
	if [ -f "$winhome/.vimrc" ]; then
		cp_if_needed .vimrc "$winhome/.vimrc"
	fi
	# GNU Emacs
	if [ -d "$winhome/.emacs.d" ]; then
		find .emacs.d -type f |
		while IFS= read -r fn; do
			cp_if_needed "$fn" "$winhome/$fn"
		done
	fi
	# GNU nano
	if command -v nano.exe >/dev/null 2>&1; then
		# Win32 nano has spellcheck disabled; comment out that line.
		nanorc_tmp="$(mktemp)"
		trap 'rm -f -- "$nanorc_tmp"' EXIT
		sed 's/^\(set speller\)/#\1/' < nanorc > "$nanorc_tmp"
		# Git Bash nano and okibcn/nano-for-windows read the nanorc from ~/.config,
		# like the Unix versions.
		cp_if_needed "$nanorc_tmp" "$winhome/.config/nano/nanorc"
		# lhmouse/nano-win reads the nanorc from %USERPROFILE%\.nanorc
		# (unprivileged) or %ALLUSERSPROFILE%\.nanorc (privileged)
		cp_if_needed "$nanorc_tmp" "$winhome/.nanorc"
		cp_if_needed "$nanorc_tmp" "$cdrive/ProgramData/.nanorc"
	fi
	# Textadept
	if command -v textadept.exe >/dev/null 2>&1; then
		cpr_if_needed .textadept "$winhome/.textadept"
	fi
fi
