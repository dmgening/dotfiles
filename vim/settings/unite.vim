let g:unite_source_menu_menus = {}
let g:unite_source_menu_menus.git = {
    \ 'description' : '            gestionar repositorios git'
        \'                            ⌘ [espacio]g',
    \}
let g:unite_source_menu_menus.git.command_candidates = [
    \['git status  ', 'Gstatus'],
    \['git diff    ', 'Gdiff'],
    \['git commit  ', 'Gcommit'],
    \['git log     ', 'exe "silent Glog | Unite quickfix"'],
    \['git blame   ', 'Gblame'],
    \['git stage   ', 'Gwrite'],
    \['git checkout', 'Gread'],
    \['git rm      ', 'Gremove'],
    \['git mv      ', 'exe "Gmove " input("Destination: ")'],
    \['git push    ', 'Git! push'],
    \['git pull    ', 'Git! pull'],
    \['git prompt  ', 'exe "Git! " input("Command: ")'],
    \['git cd      ', 'Gcd'],
\]

nnoremap <silent><Leader>F :<C-u>Unite -silent -buffer-name=files buffer file_mru file<cr>
nnoremap <silent><Leader>f :<C-u>Unite -silent -buffer-name=files buffer file file/new<cr>
nnoremap <silent><Leader>p :<C-u>Unite -silent -buffer-name=lcdmru -default-action=lcd directory_mru<cr>
nnoremap <silent><Leader>s :<C-u>Unite -silent -buffer-name=grep grep:%<cr>
nnoremap <silent><Leader>S :<C-u>Unite -silent -buffer-name=grep grep:.<cr>
nnoremap <silent><Leader>c :Unite -silent -start-insert menu:git<CR>
let g:unite_split_rule = "botright"
let g:unite_force_overwrite_statusline = 0
let g:unite_winheight = 20
let g:unite_candidate_icon=">"

"autocmd FileType unite call s:unite_my_settings()

function! s:unite_my_settings()"{{{"{{{
    " Overwrite settings.

    imap <buffer> <ESC> <Plug>(unite_exit)
    imap <buffer> <C-w> <Plug>(unite_delete_backward_path)
    imap <buffer> <C-z> <Plug>(unite_toggle_transpose_window)
    imap <buffer> <C-r> <Plug>(unite_narrowing_input_history)
    imap <silent><buffer><expr> <C-s>     unite#do_action('split')

    let unite = unite#get_current_unite()
    if unite.profile_name ==# 'search'
        nnoremap <silent><buffer><expr> r     unite#do_action('replace')
    else
        nnoremap <silent><buffer><expr> r     unite#do_action('rename')
    endif

    nnoremap <silent><buffer><expr> cd     unite#do_action('lcd')
    nnoremap <buffer><expr> S      unite#mappings#set_current_filters(
            \ empty(unite#mappings#get_current_filters()) ?
            \ ['sorter_reverse'] : [])

    " Runs "split" action by <C-s>.
endfunction"}}}"}}}
