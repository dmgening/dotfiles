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

