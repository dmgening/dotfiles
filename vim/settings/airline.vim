let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1


" TODO: Fix gui colors
let s:N1  = ['#00005f', '#dfff00', 15, 4 ]
let s:N2  = ['#ffffff', '#444444', 15, 3 ]
let s:N3  = ['#9cffd3', '#202020', 15, 8 ]
let s:I1  = ['#00005f', '#00dfff', 15, 1 ]
let s:I2  = ['#ffffff', '#005fff', 15, 8 ]
let s:I3  = ['#ffffff', '#000080', 15, 8 ]
let s:V1  = ['#000000', '#ffaf00', 15, 1 ]
let s:V2  = ['#000000', '#ff5f00', 15, 1 ]
let s:V3  = ['#ffffff', '#5f0000', 15, 1 ]
let s:IA1 = ['#4e4e4e', '#1c1c1c', 239, 234]
let s:IA2 = ['#4e4e4e', '#262626', 239, 235]
let s:IA3 = ['#4e4e4e', '#303030', 239, 236]

let g:airline#themes#swayr#palette = {}
let g:airline#themes#swayr#palette.normal = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
let g:airline#themes#swayr#palette.normal_modified = {'airline_c': ['#ffffff', '#5f005f', 15, 12, ''],}
let g:airline#themes#swayr#palette.insert = airline#themes#generate_color_map(s:I1, s:I2, s:I3)
let g:airline#themes#swayr#palette.insert_modified = {'airline_c': ['#ffffff', '#5f005f', 15, 8, ''], }
let g:airline#themes#swayr#palette.insert_paste = {'airline_a': [ s:I1[0], '#d78700', s:I1[2], 8, ''],}
let g:airline#themes#swayr#palette.visual = airline#themes#generate_color_map(s:V1, s:V2, s:V3)
let g:airline#themes#swayr#palette.visual_modified = {'airline_c': ['#ffffff', '#5f005f', 255, 53, ''],}
let g:airline#themes#swayr#palette.replace = copy(g:airline#themes#swayr#palette.insert)
let g:airline#themes#swayr#palette.replace.airline_a = [s:I2[0], '#af0000', s:I2[2], 124, '']
let g:airline#themes#swayr#palette.replace_modified = g:airline#themes#swayr#palette.insert_modified
let g:airline#themes#swayr#palette.inactive = airline#themes#generate_color_map(s:IA1, s:IA2, s:IA3)
let g:airline#themes#swayr#palette.inactive_modified = {'airline_c': [ '#875faf' , '' , 97 , '' , '' ] ,}
let g:airline#themes#swayr#palette.accents = {'red': ['#ff0000', '', 160, '']}

let g:airline_theme='swayr'
