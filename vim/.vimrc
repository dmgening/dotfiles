set nocompatible
filetype off

"" Package managment
source ~/.vim/plug.vim

"" Load settings
for f in split(glob('~/.vim/settings/*'), '\n')
        exe 'source' f
endfor

"" ## Common options
set noswapfile nobackup nowritebackup
set relativenumber
set incsearch smartcase
set backspace=2
set lazyredraw
syntax on

"" Prefare spaces over tabs
set tabstop=4 softtabstop=4 shiftwidth=4
set shiftround expandtab

"" Colors
set t_Co=256
set background=dark
colorscheme peacock

"" Allow hidden buffers
set hidden

"" Annoy me
match Error /\s\+$/

"" Status lines
set laststatus=2
set noshowmode
set showtabline=2
set guioptions=gm

autocmd FileType python setlocal et sts=4 ts=4 sw=4

" Autoresize splits
au VimResized * exe "normal! \<c-w>="

" folding method
set foldmethod=marker
