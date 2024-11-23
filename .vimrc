" (neo)vim initialization
" ~/.vimrc for vim
" ~/.config/nvim/init.vim for neovim

" if vim, change most defaults to be similar to neovim;
" this establishes a common baseline
if !has('nvim')
	set nocompatible
	set autoindent
	set autoread
	set background=dark
	set backspace=eol,start,indent
	set belloff=all
	set complete=.,w,b,u,t
	set cscopeverbose
	set display=lastline
	set encoding=utf-8
	set formatoptions=tcqj
	set nofsync
	set hidden
	set history=10000
	set hlsearch
	set incsearch
	set nojoinspaces
	set langnoremap
	set laststatus=2
	set listchars="tab:> ,trail:-,nbsp:+"
	set mouse=nvi
	set mousemodel=popup_setpos
	set nrformats=bin,hex
	set ruler
	set sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize,slash,unix
	set shortmess=filnxtToOF
	set showcmd
	set sidescroll=1
	set smarttab
	set nostartofline
	set tabpagemax=50
	set ttimeoutlen=50
	set ttyfast
	set viewoptions=folds,cursor,curdir,slash,unix
	set viminfo+=!
	set wildmenu
	filetype plugin indent on
endif

set nowrap
set mouse=
set smartindent
set scrolloff=8
set ignorecase
set smartcase
set showmatch
set matchtime=2
set wildignore+=*.a,*.o,*.obj,*.exe,*.pdb,*.ilk

" live dangerously
set nobackup
set nowritebackup
set noswapfile

" two spaces after a sentence
set joinspaces
set cpoptions+=J

" text formatting
autocmd FileType asciidoc,doxygen,markdown,rst,text setlocal formatoptions+=tn
set textwidth=80
autocmd FileType gitcommit setlocal textwidth=72
nnoremap Q gqap
inoremap <A-q> <C-o>gqap

" fix inconsistency: make Y behave like other capital-letter commands
nnoremap Y y$

" save without leaving insert mode
inoremap <C-s> <C-o>:w<CR>

" move between windows faster
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" quicklist navigation
nmap <F3> :cp<CR>
nmap <F4> :cn<CR>

" switch pwd to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<CR>

" make it easier to copy to/from clipboard
noremap <Leader>y "+y
noremap <Leader>p "+p
noremap <Leader>Y "*y
noremap <Leader>P "*p

" copy/paste without indentation
set pastetoggle=<F2>

" delete trailing white space on save
func! Trimwhite()
	if !exists('b:notrimwhite')
		exe "normal mz"
		%s/\s\+$//ge
		exe "normal `z"
	endif
endfunc
" enabled for everything but patch files
autocmd BufWrite * call Trimwhite()
autocmd FileType diff let b:notrimwhite=1

" change tab settings quickly
func! s:Tab(t, global)
	if a:global
		let l:set = 'set'
	else
		let l:set = 'setlocal'
	endif
	if a:t < 0
		" negative tab value means soft tabs
		let l:tab = -a:t
		execute l:set . ' expandtab'
	else
		let l:tab = a:t
		execute l:set . ' noexpandtab'
	endif
	execute l:set . ' shiftwidth=' . l:tab . ' softtabstop=' . l:tab . ' tabstop=' . l:tab
endfunc
" update local tab settings
func! Tab(t)
	call s:Tab(a:t, 0)
endfunc
" update global tab settings
func! TAB(t)
	call s:Tab(a:t, 1)
endfunc
" defaults
call TAB(8)
autocmd FileType make call Tab(8)
autocmd FileType lisp,scheme Tab(-2)
autocmd Filetype html setlocal indentexpr=

" path to plug.vim (junegunn/vim-plug)
func! s:VimPlugPath()
	" plug.vim path differs between neovim and vim
	if has('nvim')
		if has('win32')
			let l:plug_vim_path = '~/AppData/Local/nvim-data/site/autoload/plug.vim'
		else
			let l:plug_vim_path = '~/.local/share/nvim/site/autoload/plug.vim'
		endif
	else
		if has('win32')
			let l:plug_vim_path = '~/vimfiles/autoload/plug.vim'
		else
			let l:plug_vim_path = '~/.vim/autoload/plug.vim'
		endif
	endif
	return expand(l:plug_vim_path)
endfunc

" has junegunn/vim-plug been installed?
func! s:VimPlugIsInstalled()
	return filereadable(s:VimPlugPath())
endfunc

" skip the plugin initialization if the plugin manager hasn't been installed
if s:VimPlugIsInstalled()
	call plug#begin()
	Plug 'ctrlpvim/ctrlp.vim', { 'on': 'CtrlP' }
		nmap <C-P> :CtrlP<CR>
		let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
	Plug 'editorconfig/editorconfig-vim'
	Plug 'fatih/vim-go', { 'for': 'go' }
	Plug 'jamessan/vim-gnupg'
	Plug 'ludovicchabant/vim-gutentags'
	Plug 'majutsushi/tagbar', { 'on': 'TagbarToggle' }
		let g:tagbar_sort = 0
		nmap <F6> :TagbarToggle<CR>
	Plug 'moll/vim-bbye'
		nnoremap <Leader>q :Bdelete<CR>
	Plug 'rhysd/git-messenger.vim', { 'on': 'GitMessenger' }
		let g:git_messenger_no_default_mappings = v:true
		let g:git_messenger_always_into_popup = v:true
		nmap <F8> :GitMessenger<CR>
	Plug 'tpope/vim-commentary'
	Plug 'tpope/vim-eunuch'
	Plug 'tpope/vim-fugitive'
	call plug#end()
endif

" must be last: plug#end() executes `syntax on`
syntax off
