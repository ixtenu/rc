require('vis') -- load standard vis module
require('plugins/filetype') -- file type detection
require('plugins/complete-filename') -- C-x C-f & C-x C-o
require('plugins/complete-word') -- C-n

-- vis-plug: a minimal plugin/theme manager for vis.  initialize with:
-- git clone https://github.com/erf/vis-plug ~/.config/vis/plugins/vis-plug
local plug = require('plugins/vis-plug')
local plugins = {
	-- theme which uses a transparent background and the terminal foreground
	{ 'erf/vis-minimal-theme', theme = true, file = 'dark-clear' },
	-- support for ctags; C-] goto, C-t go back
	{ 'kupospelov/vis-ctags' },
	-- comment toggle; gcc (normal), gc (visual)
	{ 'lutobler/vis-commentary' },
	-- save cursor position per file
	{ 'erf/vis-cursors' },
	-- per file type settings in visrc.lua
	{ 'jocap/vis-filetype-settings', file = 'vis-filetype-settings' },
	-- :fzfmru fuzzy open recently used files
	{ 'peaceant/vis-fzf-mru', file = 'fzf-mru', alias = 'fzf_mru' },
	-- :fzf fuzzy file open, C-s open in split, C-v open in vertical split
	{ 'https://git.sr.ht/~mcepl/vis-fzf-open' },
	-- open a URL with gx
	{ 'https://gitlab.com/mcepl/vis-jump' },
	-- vim-like quickfix commands
	{ 'https://repo.or.cz/vis-quickfix' },
	-- set syntax based on the shebang (#!)
	{ 'e-zk/vis-shebang' },
	-- smart deletion of spaces used for indentation
	{ 'ingolemo/vis-smart-backspace', alias = 'smart_backspace' },
	-- jump to text specified by two characters;
	-- sxy jump forward to xy, Sxy jump backward to xy, n next, N prev
	{ 'erf/vis-sneak' },
	-- spellcheck; C-w e enable, C-w d disable, F7 toggle, C-w w fix
	{ 'https://gitlab.com/muhq/vis-spellcheck', alias = 'spellcheck' },
	-- alternative to :< invoked as :R
	{ 'seifferth/vis-super-shellout', file = 'super-shellout' },
}
plug.init(plugins, true)

-- for vis-filetype-settings
settings = {
	-- some languages have indentation conventions
	go = {"set expandtab off", "set tabwidth 8"},
	makefile = {"set expandtab off", "set tabwidth 8"},
	python = {"set expandtab on", "set tabwidth 4"},
	rust = {"set expandtab on", "set tabwidth 4"},
	zig = {"set expandtab on", "set tabwidth 4"},
}

-- for vis-shebang
-- note: vis has built-in shebang support since commit 2e8c73b488
shebangs = {
	["#!/bin/awk -f"] = "awk",
	["#!/bin/gawk -f"] = "awk",
	["#!/bin/rc"] = "rc",
	["#!/usr/bin/awk -f"] = "awk",
	["#!/usr/bin/env -S awk -f"] = "awk",
	["#!/usr/bin/env python"] = "python",
	["#!/usr/bin/env python3"] = "python",
	["#!/usr/bin/env sh"] = "bash",
	["#!/usr/bin/gawk -f"] = "awk",
	["#!/usr/bin/python"] = "python",
	["#!/usr/bin/python3"] = "python",
	["#!/usr/local/plan9/bin/rc"] = "rc",
}

-- global configuration options
vis.events.subscribe(vis.events.INIT, function()
	-- for Konsole: https://github.com/martanne/vis/issues/930
	vis:command('set change-256colors off')

	-- vis-fzf-mru
	plug.plugins.fzf_mru.fzfmru_history = 64
	vis:map(vis.modes.NORMAL, " b", ":fzfmru<Enter>")

	-- vis-fzf-open shortcut
	vis:command('map! normal <C-p> :fzf<Enter>')

	-- vis-smart-backspace uses a global variable for tab width;
	-- most commonly, when expandtab is on, this should be 4
	plug.plugins.smart_backspace.tab_width = 4

	-- vis-spellcheck settings; use aspell(1) rather than enchant(1)
	plug.plugins.spellcheck.cmd = "aspell -l %s -a"
	plug.plugins.spellcheck.list_cmd = "aspell list -l %s -a"
	plug.plugins.spellcheck.default_lang = "en_US"
end)

-- per-window configuration options
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	vis:command('set autoindent')
end)

-- file save hook to clean up the white space
vis.events.subscribe(vis.events.FILE_SAVE_PRE, function(file, path)
	-- convert \r\n to \n (vis only supports Unix newlines)
	for i=1, #file.lines do
		if string.match(file.lines[i], '\r$') then
			file.lines[i] = string.gsub(file.lines[i], '\r$', '')
		end
	end

	-- are we saving a patch file?  if file is in the current window (as
	-- it will be for a normal :w command), then we can check the window's
	-- syntax.  but if file is not the current window (e.g., a non-focused
	-- window being saved by :X w), then all we have to go on is the file
	-- name; assume *.patch and *.diff files are patches.
	local is_patch =
		string.match(file.name, '.patch$') or
		string.match(file.name, '.diff$') or
		(vis.win.file == file and vis.win.syntax == 'diff')

	-- trim trailing white space (except for patch files)
	if not is_patch then
		for i=1, #file.lines do
			if string.match(file.lines[i], '[ \t]$') then
				file.lines[i] = string.gsub(file.lines[i], '[ \t]*$', '')
			end
		end
	end

	-- ensure there is one (and only one) newline at EOF
	if file.size > 0 then
		if file:content(file.size-1, 1) == '\n' then
			while file.size > 1 and file:content(file.size-2, 1) == '\n' do
				file:delete(file.size-2, 1)
			end
		else
			file:insert(file.size, '\n')
		end
	end

	return true
end)
