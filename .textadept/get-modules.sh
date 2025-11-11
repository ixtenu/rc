#!/usr/bin/env sh
set -eu

scriptdir="$(cd -- "$(dirname $(readlink -f "$0"))" >/dev/null 2>&1 && pwd -P)"
cd "$scriptdir"

if [ -d modules ]; then
	echo "$PWD/modules already exists: skipping download of modules ZIP file."
	echo "Delete that directory if you want to reinitialize the Textadept modules."
else
	ta_ver="$(textadept --version | sed 1q | sed 's/Textadept //')"
	curl -O -L https://github.com/orbitalquark/textadept/releases/download/textadept_${ta_ver}/textadept_${ta_ver}.modules.zip
	unzip textadept_${ta_ver}.modules.zip
	rm textadept_${ta_ver}.modules.zip
	mv textadept-modules modules
fi

cd modules

[ ! -d scratch ] && git clone https://github.com/orbitalquark/textadept-scratch.git scratch
[ ! -d ctags ] && git clone https://github.com/orbitalquark/textadept-ctags.git ctags
[ ! -d editorconfig-sc ] && git clone https://github.com/ixtenu/ta-editorconfig-sc editorconfig-sc

find . -maxdepth 2 -name '\.git' |
while IFS= read -r g; do
	pushd "$(dirname $g)"
	git pull
	popd
done
