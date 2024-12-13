" GUI (neo)vim initialization
" ~/.gvimrc for vim
" ~/.config/nvim/ginit.vim for neovim

" enable mouse
set mouse=a

" enable system clipboard integration
set clipboard^=unnamed,unnamedplus

" enable a GUI scrollbar
if exists('GuiScrollBar')
	GuiScrollBar 1
endif

" customize the GUI font
if exists(':GuiFont')
	" default font
	let s:fontsize = 13
	let s:fontname = "Go Mono"
	:execute "GuiFont! " . s:fontname . ":h" . s:fontsize

	" resize font with ctrl-scrollwheel
	" based on: https://stackoverflow.com/a/51424640
	function! AdjustFontSize(amount)
		let s:fontsize = s:fontsize + a:amount
		:execute "GuiFont! " . s:fontname . ":h" . s:fontsize
	endfunction
	noremap <C-ScrollWheelUp> :call AdjustFontSize(1)<CR>
	noremap <C-ScrollWheelDown> :call AdjustFontSize(-1)<CR>
	inoremap <C-ScrollWheelUp> <Esc>:call AdjustFontSize(1)<CR>a
	inoremap <C-ScrollWheelDown> <Esc>:call AdjustFontSize(-1)<CR>a
endif
