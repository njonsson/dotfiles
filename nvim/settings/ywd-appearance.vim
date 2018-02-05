if has("gui_running")
  " Show tab number (useful for Cmd-1, Cmd-2.. mapping)
  " For some reason this doesn't work as a regular set command,
  " (the numbers don't show up) so I made it a VimEnter event
  autocmd VimEnter * set guitablabel=%N:\ %t\ %M

  set lines=60
  set columns=190

  if has("gui_gtk2")
    set guifont=Inconsolata-dz\ 12,Inconsolata\ 15,Monaco\ 12
  else
    set guifont=Inconsolata-dz:h14,Inconsolata:h17,Monaco:h14
  endif
endif

" let g:airline_theme='solarized'

" set nocompatible
"
" filetype on
" filetype plugin on
" filetype indent on
" syntax on
"
" autocmd BufEnter * set relativenumber
" autocmd BufLeave * set norelativenumber
" set cursorline
set colorcolumn=81

" Solarized color scheme
" syntax enable
set background=dark
colorscheme solarized
set mouse=a
