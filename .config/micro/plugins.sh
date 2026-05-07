#!/usr/bin/env sh
set -eux
micro -plugin install autofmt
micro -plugin install editorconfig
micro -plugin install fzf
micro -plugin install go
micro -plugin install joinLines
micro -plugin install jump
micro -plugin install manipulator
micro -plugin update
