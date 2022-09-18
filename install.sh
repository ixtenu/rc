#!/usr/bin/env sh
set -eu

scriptdir="$(cd -- "$(dirname "$0")" 2>&1 >/dev/null && pwd -P)"
cd "$scriptdir"

installfile() {
	lnvopt='-v'
	[ "$(uname)" = "OpenBSD" ] && lnvopt=''

	fn="$1"
	fp="$(readlink -f $fn)"
	od="$2"
	lp="$od"/"$fn"
	mkdir -p "$od"
	if [ -e "$lp" ]; then
		if [ -L "$lp" ]; then
			ln -sf $lnvopt "$fp" "$lp"
		else
			echo "warning: $lp exists and is not a symbolic link, leaving it" 2>&1
		fi
	else
		ln -s $lnvopt "$fp" "$lp"
	fi
}

if command -v X 2>&1 >/dev/null; then
	installfile .Xresources "$HOME"
fi
if command -v cwm 2>&1 >/dev/null; then
	installfile .cwmrc "$HOME"
fi
if command -v joe 2>&1 >/dev/null; then
	installfile .joerc "$HOME"
	installfile .jmacsrc "$HOME"
fi
if command -v mg 2>&1 >/dev/null; then
	installfile .mg "$HOME"
fi
if command -v sam 2>&1 >/dev/null; then
	# .samrc is for deadpixi/sam; don't install it for 9fans/plan9port sam
	if [ -x /usr/local/bin/sam ]; then
		installfile .samrc "$HOME"
	fi
fi
if command -v zsh 2>&1 >/dev/null; then
	installfile .zshrc "$HOME"
fi
