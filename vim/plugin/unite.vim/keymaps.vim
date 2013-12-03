

nnoremap <silent><Leader>F :<C-u>Unite -silent -buffer-name=files buffer file_mru file_rec/async:!<cr>
nnoremap <silent><Leader>f :<C-u>Unite -silent -buffer-name=files buffer file file/new<cr>
nnoremap <silent><Leader>p :<C-u>Unite -silent -buffer-name=files -default-action=lcd directory_mru<cr>
nnoremap <silent><Leader>s :<C-u>Unite -silent -buffer-name=files grep:%<cr>
nnoremap <silent><Leader>S :<C-u>Unite -silent -buffer-name=files grep:.<cr>
nnoremap <silent><Leader>c :Unite -silent -start-insert menu:git<CR>
