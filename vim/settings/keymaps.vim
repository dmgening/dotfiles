" vim: ft=vim
set langmap=ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯЖ;ABCDEFGHIJKLMNOPQRSTUVWXYZ:,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz

" hlsearch switcher
function! ToggleHLSearch()
	if(&hlsearch == 1)
		set nohlsearch
	else
		set hlsearch
	endif
endfunc
nnoremap <Leader>/ :call ToggleHLSearch()<cr>
nnoremap # :set hlsearch<cr>#
nnoremap ? :set hlsearch<cr>?
nnoremap / :set hlsearch<cr>/

" Buffer managment
nnoremap <silent>gb :bnext<cr>
nnoremap <silent>gB :bprev<cr>

nnoremap <silent><leader>n :enew<cr>
nnoremap <silent><leader>d :confirm bdelete<cr>
nnoremap <silent><leader>w :confirm write<cr>
nnoremap <silent><leader>e :confirm edit<cr>

" Show hidden chars
nmap <Leader>eh :set list!<CR>
set listchars=tab:→\ ,eol:↵,trail:·,extends:↷,precedes:↶

