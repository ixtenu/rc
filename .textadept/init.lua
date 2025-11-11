-- Modules
require('ctags')
require('file_diff')
local format = require('format')
require('scratch')

local editorconfig = require('editorconfig-sc')
editorconfig.setup()

-- Font
if not CURSES then view:set_theme{font = 'Cascadia Code', size = 13} end

-- Highlight all instances of the current word
textadept.editing.highlight_words = textadept.editing.HIGHLIGHT_CURRENT

-- Increase maximum file list size (default is 5000)
io.quick_open_max = 32768

-- Always ensure final newline (this is false by default on Windows)
io.ensure_final_newline = true

-- Don't automatically pair quotation marks, parentheses, etc.
textadept.editing.auto_pairs = nil

-- Wrap lines at 80 characters
format.line_length = 80

-- Always strip trailing spaces, except in patch files.
local function set_strip_trailing_spaces()
	textadept.editing.strip_trailing_spaces = buffer.lexer_language ~= 'diff'
end
events.connect(events.LEXER_LOADED, set_strip_trailing_spaces)
events.connect(events.BUFFER_AFTER_SWITCH, set_strip_trailing_spaces)
events.connect(events.VIEW_AFTER_SWITCH, set_strip_trailing_spaces)

-- Default indentation settings for all buffers.
buffer.use_tabs = true
buffer.tab_width = 8

-- Indentation settings for individual languages.
events.connect(events.LEXER_LOADED, function(name)
	if name == 'python' or name == 'yaml' or name == 'zig' then
		buffer.use_tabs = false
		buffer.tab_width = 4
	end
end)
