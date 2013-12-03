let g:unite_enable_start_insert = 1
let g:unite_split_rule = "botright"
let g:unite_force_overwrite_statusline = 0
let g:unite_winheight = 10
let g:unite_candidate_icon=">"

autocmd FileType unite call s:unite_my_settings()
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
