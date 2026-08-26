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
" Vundle has no 'branch' option (unlike vim-plug) and clones shallowly,
" so after :PluginInstall this sits on unbuilt TypeScript source. Fetch
" and switch to the prebuilt 'release' branch manually — see README.
Plugin 'neoclide/coc.nvim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'tpope/vim-fugitive'
Plugin 'ryanoasis/vim-devicons'
Plugin 'airblade/vim-gitgutter.git'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
" Renders via the external 'code-minimap' binary (cargo install
" --locked code-minimap); Vundle has no post-install hook to fetch it
" automatically, so that step is manual — see README.
Plugin 'wfxr/minimap.vim'

call vundle#end()

""""""""""""""""""""""""""""
" Coc.nvim Language Servers"
""""""""""""""""""""""""""""
" JavaScript/TypeScript, Python, and C/C++ come from coc extensions.
" Listing them here makes coc auto-install any that are missing on
" startup, so normally no manual :CocInstall is needed. Vue is wired up
" manually below because it needs the isolated TypeScript SDK and hybrid
" mode disabled.
let g:coc_global_extensions = ['coc-tsserver', 'coc-pyright', 'coc-clangd']

let g:coc_user_config = {
      \ 'languageserver': {
      \   'vue': {
      \     'command': expand('~/.local/share/vue-language-server/node_modules/.bin/vue-language-server'),
      \     'args': ['--stdio'],
      \     'filetypes': ['vue'],
      \     'initializationOptions': {
      \       'typescript': {
      \         'tsdk': expand('~/.local/share/vue-language-server/node_modules/typescript/lib')
      \       },
      \       'vue': {
      \         'hybridMode': v:false
      \       }
      \     },
      \     'rootPatterns': [
      \       'package.json',
      \       'vite.config.js',
      \       'vite.config.ts',
      \       'vue.config.js',
      \       'tsconfig.json',
      \       'jsconfig.json'
      \     ]
      \   }
      \ }
      \ }

""""""""""""""""""""""""""""
" General Config           "
""""""""""""""""""""""""""""
let mapleader = ' '
let maplocalleader = ' '

" Start at $VIMRC_DEFAULT_CWD when set and valid, otherwise the home
" directory. This keeps the same vimrc usable across machines,
" containers, and sandboxes with different layouts.
let s:cwd_dir = empty($VIMRC_DEFAULT_CWD) ? expand('~') : expand($VIMRC_DEFAULT_CWD)
if !isdirectory(s:cwd_dir)
  let s:cwd_dir = expand('~')
endif
if isdirectory(s:cwd_dir)
  execute 'cd ' . fnameescape(s:cwd_dir)
endif

set nomodeline
filetype plugin indent on
syntax enable

set hidden
set fileformats=unix,dos
set encoding=utf-8
set clipboard=unnamedplus

set number
set cursorline
set signcolumn=yes
set scrolloff=5
set sidescrolloff=5
set splitbelow
set splitright

set nowrap
set textwidth=0

set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2

set ignorecase
set smartcase
set incsearch
set hlsearch

augroup search_highlight_lifecycle
  autocmd!
  " Clear any old search synchronously when leaving Insert mode.
  autocmd InsertLeave * silent! nohlsearch
augroup END

" Coc.nvim recommends a plain popup menu with no automatic insertion;
" it shows documentation in its own floating window instead of a preview
" split.
set completeopt=menuone,noinsert,noselect
set shortmess+=c

" Update GitGutter signs promptly.
set updatetime=100

" Retain undo history across Vim sessions.
if has('persistent_undo')
  let s:undo_dir = expand('~/.vim/undo')
  if !isdirectory(s:undo_dir)
    call mkdir(s:undo_dir, 'p', 0700)
  endif
  let &undodir = s:undo_dir . '//'
  set undofile
endif

if has('gui_running')
  set guifont=Courier\ New:h14
endif

set background=dark
colorscheme desert

""""""""""""""""""""""""""""
" Coc.nvim Completion      "
""""""""""""""""""""""""""""
function! s:CheckBackspace() abort
  let l:col = col('.') - 1
  return !l:col || getline('.')[l:col - 1] =~# '\s'
endfunction

inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ <SID>CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr> <S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>"

""""""""""""""""""""""""""""
" Coc.nvim Navigation, Refactoring, and Diagnostics
""""""""""""""""""""""""""""
nnoremap <silent> <leader>jd <Plug>(coc-definition)
nnoremap <silent> <leader>jr <Plug>(coc-references)
nnoremap <silent> <leader>jt <Plug>(coc-type-definition)
nnoremap <silent> <leader>jh :call CocActionAsync('doHover')<CR>
nnoremap <leader>jn <Plug>(coc-rename)
nnoremap <silent> <leader>jf <Plug>(coc-fix-current)

" Show refactor actions (extract to function/constant, etc.) available
" for the current position or visual selection, when the attached
" language server offers any.
nmap <silent> <leader>ja <Plug>(coc-codeaction-cursor)
xmap <silent> <leader>ja <Plug>(coc-codeaction-selected)

nnoremap <silent> <leader>do :CocDiagnostics<CR>
nnoremap <silent> <leader>dc :lclose<CR>
nnoremap <silent> ]d <Plug>(coc-diagnostic-next)
nnoremap <silent> [d <Plug>(coc-diagnostic-prev)

function! s:DiagnosticsWindowOpen() abort
  for l:winnr in range(1, winnr('$'))
    if get(getwininfo(win_getid(l:winnr))[0], 'loclist', 0)
      return 1
    endif
  endfor
  return 0
endfunction

function! s:FillDiagnosticsDeferred(bufnr, timer) abort
  " Deferred via timer_start(0, ...): BufEnter fires synchronously as
  " part of :e, but coc's own attach handshake with its Node backend for
  " a newly-entered buffer is asynchronous, so calling fillDiagnostics
  " directly here can race it ("Buffer N not exists"). Running on the
  " next event-loop tick lets that attach finish first.
  "
  " Guarded against a second, newer BufEnter having already superseded
  " this one by the time the timer fires (e.g. a fast double buffer
  " switch): only apply if the current buffer still matches what was
  " captured at schedule time, so a stale callback can't clobber a
  " later, correct update — last real switch always wins.
  if bufnr('%') != a:bufnr || !s:DiagnosticsWindowOpen()
    return
  endif
  silent! call coc#rpc#request('fillDiagnostics', [a:bufnr])
  " fillDiagnostics alone updates the underlying location-list data but
  " does not redraw an already-open location-list window to show it —
  " that needs an explicit :lopen nudge. win_execute() runs :lopen
  " scoped to this window: it refreshes the existing window in place,
  " without moving focus or opening a duplicate.
  silent! call win_execute(win_getid(), 'lopen')
endfunction

" Keep the diagnostics list in sync with whichever file is current:
" refresh its contents (not focus) on every real BufEnter, but only when
" the window is already open somewhere in this tab — this never forces it
" open, and never fires while browsing an auxiliary window (NERDTree,
" minimap, the diagnostics window itself), which would blank the list.
augroup coc_diagnostics_autoupdate
  autocmd!
  autocmd BufEnter * if !s:IsAuxiliaryWindow(winnr()) && s:DiagnosticsWindowOpen() |
        \ call timer_start(0, function('s:FillDiagnosticsDeferred', [bufnr('%')])) | endif
augroup END

""""""""""""""""""""""""""""
" NERDTree                 "
""""""""""""""""""""""""""""
augroup nerdtree_lifecycle
  autocmd!
  " Start NERDTree and move cursor to the file window.
  autocmd VimEnter * if argc() == 0 && !exists('s:std_in') && v:this_session == '' | NERDTree | wincmd p | endif

  " Close the tab/Vim when only auxiliary windows (NERDTree, minimap,
  " quickfix/loclist) remain. Closes them directly via :close/:quit rather
  " than feedkeys()-ing ":quit<CR>": that string goes through the very
  " same <CR> cnoremap as real typed input (both ours and NERDTree's own
  " buffer-local one, which deliberately dodges closing the NERDTree
  " window itself), making the old approach dependent on exactly which
  " window ends up focused. This closes everything auxiliary in one go.
  autocmd BufEnter * call s:QuitIfOnlyAuxiliaryWindowsRemain()

  " Keep file buffers from replacing the NERDTree window. Guarded against
  " quickfix/location-list windows: those span the full width, so
  " winnr('h') returns their own window number and would otherwise make
  " this misfire as if it were the leftmost (NERDTree) window.
  autocmd BufEnter * if &buftype !=# 'quickfix' && winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
        \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif

  " Mirror NERDTree into normal tabs, excluding temporary Glow tabs.
  autocmd BufWinEnter * if &buftype !=# 'quickfix' && getcmdwintype() ==# '' && !get(t:, 'glow_preview', 0) | silent! NERDTreeMirror | endif
augroup END

let NERDTreeShowHidden=1
let NERDTreeShowBookmarks=1
let NERDTreeCascadeOpenSingleChildDir=0
let NERDTreeCascadeSingleChildDir=0
let NERDTreeWinSize=45

""
"  NERDTree workflow helpers
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

" True for a sidebar/panel window (NERDTree, the minimap, a quickfix or
" location list) as opposed to a window showing real file content. Shared
" by every "route this command to a real window" and "quit when nothing
" real is left" check below, so a new panel type only needs updating here.
function! s:IsAuxiliaryWindow(winnr) abort
  let l:buf = winbufnr(a:winnr)
  if s:BufferHasNERDTree(l:buf) || getbufvar(l:buf, '&filetype') ==# 'minimap'
    return 1
  endif
  let l:info = getwininfo(win_getid(a:winnr))[0]
  return get(l:info, 'loclist', 0) || get(l:info, 'quickfix', 0)
endfunction

" True when every remaining window is auxiliary rather than real file
" content. Used to decide whether closing the last file window should
" quit Vim, so auxiliary windows added later don't silently defeat that
" check the way a raw winnr('$') count would.
function! s:OnlyAuxiliaryWindowsRemain() abort
  for l:winnr in range(1, winnr('$'))
    if !s:IsAuxiliaryWindow(l:winnr)
      return 0
    endif
  endfor
  return 1
endfunction

" Every window already qualified as auxiliary above, so there is nothing
" worth preserving: close them all and quit the tab (or Vim, if this is
" the last tab). Deferred via timer_start(0, ...) because Vim disallows
" changing the window layout from directly inside a BufEnter handler
" (E1312) — the timer callback runs on the next event-loop tick, once
" autocmd processing has fully unwound.
function! s:QuitIfOnlyAuxiliaryWindowsRemain() abort
  if !s:OnlyAuxiliaryWindowsRemain()
    return
  endif
  call timer_start(0, function('s:CloseAllAuxiliaryWindows'))
endfunction

function! s:CloseAllAuxiliaryWindows(timer) abort
  if !s:OnlyAuxiliaryWindowsRemain()
    return
  endif
  while winnr('$') > 1
    close
  endwhile
  quit
endfunction

" Close the current buffer, keeping the window open on something else.
" Replaces the third-party Bclose plugin, whose "no other listed buffer
" -> grab any buffer with an empty name" fallback incorrectly matched
" coc's diagnostics buffer (quickfix/location-list buffers have
" bufname() == '' despite :ls showing a bracketed placeholder for them) —
" see reviews/bclose-swallows-diagnostics-window.md. This never searches
" for a fallback beyond other genuinely listed buffers, so it can't repeat
" that mistake.
function! s:CloseBuffer() abort
  let l:target = bufnr('%')
  if s:BufferHasNERDTree(l:target) || &buftype ==# 'quickfix' || &filetype ==# 'minimap'
    return
  endif

  let l:alt = bufnr('#')
  if l:alt > 0 && l:alt != l:target && buflisted(l:alt)
    execute 'buffer' l:alt
  else
    let l:others = filter(range(1, bufnr('$')), 'buflisted(v:val) && v:val != l:target')
    if !empty(l:others)
      execute 'buffer' l:others[0]
    else
      enew
    endif
  endif

  execute 'bdelete' l:target
endfunction

function! s:NERDTreeVisible() abort
  for l:winnr in range(1, winnr('$'))
    if s:BufferHasNERDTree(winbufnr(l:winnr))
      return 1
    endif
  endfor

  return 0
endfunction

function! s:FocusFileWindow() abort
  if !s:IsAuxiliaryWindow(winnr())
    return 1
  endif

  for l:winnr in range(1, winnr('$'))
    if !s:IsAuxiliaryWindow(l:winnr)
      execute l:winnr . 'wincmd w'
      return 1
    endif
  endfor

  echoerr 'No file window available'
  return 0
endfunction

function! s:HideNERDTreeForFzf() abort
  if s:NERDTreeVisible()
    let t:restore_nerdtree_after_fzf = 1
    let t:fzf_return_winid = win_getid()
    silent! NERDTreeClose
  endif
endfunction

function! s:RestoreNERDTreeAfterFzf(...) abort
  if !get(t:, 'restore_nerdtree_after_fzf', 0)
    return
  endif

  unlet t:restore_nerdtree_after_fzf
  let l:return_winid = get(t:, 'fzf_return_winid', 0)
  unlet! t:fzf_return_winid

  silent! NERDTree

  if l:return_winid > 0 && win_id2win(l:return_winid) > 0
    call win_gotoid(l:return_winid)
  else
    call s:FocusFileWindow()
  endif
endfunction

function! s:InstallFzfNERDTreeRestoreHook() abort
  if !get(t:, 'restore_nerdtree_after_fzf', 0)
    return
  endif

  augroup fzf_nerdtree_restore_buffer
    autocmd! * <buffer>
    execute 'autocmd BufDelete,BufWipeout <buffer> call timer_start(0, function(' . string(expand('<SID>') . 'RestoreNERDTreeAfterFzf') . '))'
  augroup END
endfunction

augroup fzf_nerdtree_restore
  autocmd!
  autocmd FileType fzf call <SID>InstallFzfNERDTreeRestoreHook()
augroup END

function! s:RunInFileWindow(command) abort
  if s:FocusFileWindow()
    execute a:command
  endif
endfunction

function! s:RunFzfOutsideNERDTree(command) abort
  call s:HideNERDTreeForFzf()
  call s:RunInFileWindow(a:command)
endfunction

function! s:RunOutsideNERDTree(command) abort
  if s:BufferHasNERDTree(bufnr('%'))
    call s:RunInFileWindow(a:command)
    return
  endif

  execute a:command
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

  if getcmdtype() ==# ':' && l:command =~# '^\%(Rg\|Files\|Buffers\|Lines\|History\|Commits\|FZF\)\%($\|\s\)'
    return "\<C-U>call " . expand('<SID>') . "RunFzfOutsideNERDTree(" . string(l:command) . ")\<CR>"
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

augroup nerdtree_mappings
  autocmd!
  autocmd FileType nerdtree cnoreabbrev <buffer> bd <nop>
  autocmd FileType nerdtree cnoreabbrev <buffer> only <nop>
  autocmd FileType nerdtree cnoremap <buffer> <expr> <CR> <SID>NERDTreeCmdlineEnter()
  autocmd FileType nerdtree nnoremap <buffer> <C-p> :call <SID>RunFzfOutsideNERDTree('Files')<CR>
  autocmd FileType nerdtree nnoremap <buffer> :e <C-W>l :e
  autocmd FileType nerdtree noremap <buffer> <C-Left> <nop>
  autocmd FileType nerdtree noremap <buffer> <C-Right> <nop>
  autocmd FileType nerdtree noremap <buffer> <Esc>w <nop>
  autocmd FileType nerdtree noremap <buffer> <Esc>y <nop>
  autocmd FileType nerdtree noremap <buffer> <C-o> <nop>
  autocmd FileType nerdtree noremap <buffer> e <nop>
augroup END

" Prevent quickfix appearing on buffer cycling
augroup quickfix_workflow
  autocmd!
  autocmd FileType qf setlocal nobuflisted
augroup END

""""""""""""""""""""""""""""
" Navigation and Editing   "
""""""""""""""""""""""""""""
" Routed through the file window so cycling buffers from an auxiliary
" window (minimap, diagnostics) doesn't load the next/previous buffer
" into that panel — NERDTree already has its own <nop> override above.
nnoremap <silent> <C-Right> :call <SID>RunInFileWindow('bnext!')<CR>
nnoremap <silent> <C-Left> :call <SID>RunInFileWindow('bprevious!')<CR>
nnoremap <silent> <Up> <Up>:nohlsearch<CR>
nnoremap <silent> <Down> <Down>:nohlsearch<CR>
nnoremap <silent> <Left> <Left>:nohlsearch<CR>
nnoremap <silent> <Right> <Right>:nohlsearch<CR>

nnoremap <silent> <A-S-Left> :wincmd h<CR>
nnoremap <silent> <A-S-Right> :wincmd l<CR>

nnoremap <Esc>< <C-W><
nnoremap <Esc>> <C-W>>
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
nnoremap - <C-W>-
nnoremap + <C-W>+

" Most terminals encode Alt-key combinations as an Escape prefix.
" These mappings therefore implement Alt-w, Alt-y, and Alt-f reliably.
nnoremap <silent> <Esc>w :call <SID>CloseBuffer()<CR>
nnoremap <silent> <Esc>y :NERDTreeFind<CR>
nnoremap <silent> <Esc>f :NERDTreeToggle<CR>
" Keep *, #, g*, g#, n, and N native so search highlighting persists.
" Arrow keys and explicit clearing commands remove the current highlight.
nnoremap <silent> <leader>h :nohlsearch<CR>

""""""""""""""""""""""""""""
" Airline Config           "
""""""""""""""""""""""""""""
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_powerline_fonts = 1

""""""""""""""""""""""""""""
" Minimap Config           "
""""""""""""""""""""""""""""
let g:minimap_auto_start = 1
let g:minimap_width = 10

nnoremap <silent> <leader>mm :MinimapToggle<CR>

""""""""""""""""""""""""""""
" Theme                    "
""""""""""""""""""""""""""""
augroup theme_setup
  autocmd!
  autocmd VimEnter * ++nested silent! colorscheme gruvbox
augroup END
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

nnoremap <silent> <C-p> :call <SID>RunFzfOutsideNERDTree('Files')<CR>
nnoremap <silent> <leader>ff :call <SID>RunFzfOutsideNERDTree('Files')<CR>
nnoremap <leader>fg :call <SID>FocusFileWindow()<CR>:Rg<Space>
nnoremap <silent> <leader>fb :call <SID>RunFzfOutsideNERDTree('Buffers')<CR>
nnoremap <silent> <leader>fl :call <SID>RunFzfOutsideNERDTree('Lines')<CR>
nnoremap <silent> <leader>fh :call <SID>RunFzfOutsideNERDTree('History')<CR>
nnoremap <silent> <leader>fc :call <SID>RunFzfOutsideNERDTree('Commits')<CR>

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
