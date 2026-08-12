""""""""""""""""""""""""""""
" Vundle Config            "
""""""""""""""""""""""""""""
set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim/
call vundle#begin('~/.vim/bundle/')

Plugin 'VundleVim/Vundle.vim'
Plugin 'preservim/nerdtree'
Plugin 'morhetz/gruvbox'
Plugin 'Valloric/YouCompleteMe'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'tpope/vim-fugitive'
Plugin 'chrismccord/bclose.vim'
Plugin 'ryanoasis/vim-devicons'
"Plugin 'github/copilot.vim'
Plugin 'airblade/vim-gitgutter.git'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'

" Plugin 'vim-airline/vim-airline'
" Plugin 'chazy/cscope_maps'
" Plugin 'junegunn/fzf'
" Plugin 'junegunn/fzf.vim'
" Plugin 'Valloric/YouCompleteMe'
" Plugin 'vim-syntastic/syntastic'
" Plugin 'ivanov/vim-ipython'
" Plugin 'Shougo/vimproc.vim'
" Plugin 'chase/vim-ansible-yaml'

cal vundle#end()

""""""""""""""""""""""""""""
" Vue Language Server    "
""""""""""""""""""""""""""""
let g:ycm_language_server = [
      \ {
      \   'name': 'vue',
      \   'cmdline': [
      \     expand('~/.local/share/vue-language-server/node_modules/.bin/vue-language-server'),
      \     '--stdio'
      \   ],
      \   'filetypes': ['vue'],
      \   'settings': {
      \     'typescript': {
      \       'tsdk': expand('~/.local/share/vue-language-server/node_modules/typescript/lib')
      \     },
      \     'vue': {
      \       'hybridMode': v:false
      \     }
      \   },
      \   'project_root_files': [
      \     'package.json',
      \     'vite.config.js',
      \     'vite.config.ts',
      \     'vue.config.js',
      \     'tsconfig.json',
      \     'jsconfig.json'
      \   ]
      \ }
      \ ]

""""""""""""""""""""""""""""
" General Config           "
""""""""""""""""""""""""""""
let HOME_VIM = fnameescape('~/Repositories')
cd `=HOME_VIM`

set nomodeline
filetype plugin indent on

set hidden
set ffs=unix,dos

" Show completion documentation in a preview split and close it when
" leaving insert mode.
set completeopt-=popup
set completeopt+=preview
autocmd InsertLeave * silent! pclose

" To update git changes quickly -- asked by vim-gitgutter
set updatetime=100

" au BufRead,BufNewFile *.vue set filetype=html
" let HOME_VIM = fnameescape('C:\Work')
" cd `=HOME_VIM`

set clipboard=unnamedplus

colorscheme desert
set guifont=Courier\ New:h14

set expandtab
set shiftwidth=2
set softtabstop=2

set cursorline

set nowrap
set tw=0

syntax on
set number

set encoding=utf8

""""""""""""""""""""""""""""
" NERDTree                 "
""""""""""""""""""""""""""""
" Start NERDTree and move cursor to the other window
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') && v:this_session == '' | NERDTree | wincmd p | endif

" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif

" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif

" If another buffer tries to replace NERDTree, put it in the other window, and bring back NERDTree.
autocmd BufEnter * if winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

" Open the existing NERDTree on each new tab, except temporary Glow tabs.
autocmd BufWinEnter * if &buftype != 'quickfix' && getcmdwintype() == '' && !get(t:, 'glow_preview', 0) | silent NERDTreeMirror | endif

let NERDTreeShowHidden=1
let NERDTreeShowBookmarks=1
let NERDTreeCascadeOpenSingleChildDir=0
let NERDTreeCascadeSingleChildDir=0
let NERDTreeWinSize=45

""
"  Block commands in NERDTree
"
function! s:CmdlineEnter() abort
  if getcmdtype() ==# ':' && index(['q', 'quit'], getcmdline()) >= 0 && &modified
    return "\<C-U>echoerr 'E37: No write since last change (add ! to override)'\<CR>"
  endif

  return "\<CR>"
endfunction

cnoremap <expr> <CR> <SID>CmdlineEnter()

function! s:BufferHasNERDTree(bufnr) abort
  return !empty(getbufvar(a:bufnr, 'NERDTree', {}))
endfunction

function! s:RunInFileWindow(command) abort
  for l:winnr in range(1, winnr('$'))
    if !s:BufferHasNERDTree(winbufnr(l:winnr))
      execute l:winnr . 'wincmd w'
      execute a:command
      return
    endif
  endfor
endfunction

function! s:QuitFromNERDTree() abort
  for l:winnr in range(1, winnr('$'))
    let l:bufnr = winbufnr(l:winnr)

    if !s:BufferHasNERDTree(l:bufnr)
      if getbufvar(l:bufnr, '&modified')
        echoerr 'E37: No write since last change (add ! to override)'
        return
      endif

      execute l:winnr . 'wincmd w'
      quit
      return
    endif
  endfor
endfunction

function! s:NERDTreeCmdlineEnter() abort
  let l:command = getcmdline()

  if getcmdtype() ==# ':' && l:command =~# '^Rg\%($\|\s\)'
    return "\<C-U>call " . expand('<SID>') . "RunInFileWindow(" . string(l:command) . ")\<CR>"
  endif

  if getcmdtype() ==# ':' && index(['q', 'quit'], l:command) >= 0
    " Allow Vim/NERDTree to close a tab when the tree is its only window.
    if winnr('$') == 1
      return "\<CR>"
    endif

    return "\<C-U>call " . expand('<SID>') . "QuitFromNERDTree()\<CR>"
  endif

  return "\<CR>"
endfunction

autocmd FileType nerdtree cnoreabbrev <buffer> bd <nop>
autocmd FileType nerdtree cnoreabbrev <buffer> only <nop>
autocmd FileType nerdtree cnoremap <buffer> <expr> <CR> <SID>NERDTreeCmdlineEnter()
autocmd FileType nerdtree nnoremap <buffer> <C-p> :call <SID>RunInFileWindow('FZF')<CR>
autocmd FileType nerdtree nnoremap <buffer> :e <C-W>l :e
autocmd FileType nerdtree noremap <buffer> <C-Left> <nop>
autocmd FileType nerdtree noremap <buffer> <C-Right> <nop>
autocmd FileType nerdtree noremap <buffer> w <nop>
autocmd FileType nerdtree noremap <buffer> y <nop>
autocmd FileType nerdtree noremap <buffer> <C-o> <nop>
autocmd FileType nerdtree noremap <buffer> e <nop>

" Prevent quickfix appearing on buffer cycling
augroup qf
autocmd!
autocmd FileType qf set nobuflisted
augroup END

""""""""""""""""""""""""""""
" Shortcuts Config         "
""""""""""""""""""""""""""""
nnoremap <C-Right> :bnext!<CR>
nnoremap <C-Left> :bprevious!<CR>

nnoremap <A-S-Left>  :wincmd h<CR>
nnoremap <A-S-Right> :wincmd l<CR>

nnoremap < <C-W><
nnoremap > <C-W>>
nnoremap - <C-W>-
nnoremap + <C-W>+

nnoremap w :Bclose<CR>
nnoremap y :NERDTreeFind<CR>
nnoremap f :NERDTreeToggle<CR>

""""""""""""""""""""""""""""
" Airline Config           "
""""""""""""""""""""""""""""
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#formatter = 'default'
let g:airline#extensions#ale#enabled=1
let g:airline_powerline_fonts = 1

""""""""""""""""""""""""""""
" Theme                    "
""""""""""""""""""""""""""""
autocmd vimenter * ++nested colorscheme gruvbox
let g:airline_theme='base16'

""""""""""""""""""""""""""""
" FZF Config               "
""""""""""""""""""""""""""""
let g:fzf_history_dir='~/.vim/fzf-history'
let $FZF_DEFAULT_COMMAND='rg --files --hidden
            \ -g !target
            \ -g !.settings
            \ -g !.metadata
            \ -g !.classpath
            \ -g !.project
            \ -g !.git
            \ -g !.cache
            \ -g !node_modules
            \ 2> ~/.vim/fzf-error.log'
        
let g:fzf_layout = { 'window': 'enew' }

noremap <C-p> :FZF<CR>

""""""""""""""""""""""""""""
" Glow for markdown viewer
""""""""""""""""""""""""""""
function! s:CloseGlowTab(winid, timer) abort
  let l:location = win_id2tabwin(a:winid)

  if l:location[0] > 0
    execute 'silent! tabclose ' . l:location[0]
  endif
endfunction

function! s:GlowExited(winid, job, status) abort
  " Terminal-exit callbacks run before Vim has finished cleaning up the
  " terminal window. Defer tab cleanup until the next event-loop tick.
  call timer_start(0, function('s:CloseGlowTab', [a:winid]))
endfunction

function! GlowPreview()
  if empty(expand('%:p'))
    echoerr 'Save the Markdown file first'
    return
  endif

  write
  let l:file = expand('%:p')

  if !filereadable(l:file)
    echoerr 'File does not exist: ' . l:file
    return
  endif

  " Do not let BufWinEnter mirror NERDTree while creating the preview tab.
  noautocmd tabnew
  let t:glow_preview = 1
  let l:winid = win_getid()

  call term_start(
        \ ['glow', '-p', l:file],
        \ {
        \   'curwin': 1,
        \   'term_finish': 'close',
        \   'exit_cb': function('s:GlowExited', [l:winid])
        \ }
        \ )
endfunction

command! Glow call GlowPreview()
