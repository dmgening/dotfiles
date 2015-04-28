hi clear
syntax reset
let g:colors_name = "swayr"

set background=dark

let s:black  = ["1С1709", 0 ]
let s:red    = ["8E4317", 1 ]
let s:green  = ["787200", 2 ]
let s:yellow = ["945C00", 3 ]
let s:blue   = ["315094", 4 ]
let s:purple = ["5C2E40", 5 ]
let s:cyan   = ["00617D", 6 ]
let s:white  = ["C2B9A1", 7 ]

let s:bright_black  = ["4F4939", 8 ]
let s:bright_red    = ["F07935", 9 ]
let s:bright_green  = ["D9D138", 10]
let s:bright_yellow = ["FFAB26", 11]
let s:bright_blue   = ["8AA9ED", 12]
let s:bright_purple = ["FF8CB8", 13]
let s:bright_cyan   = ["43BDE0", 14]
let s:bright_white  = ["F2E8C9", 15]

let s:accent_red    = ["FF0000", 160]

fun <SID>HL(group, fg, bg, attr)
  let l:args = " " . a:group
  if a:fg != []
    let l:args .= " guifg=#" . a:fg[0] . " ctermfg=" . a:fg[1]
  endif
  if a:bg != []
    let l:args .= " guibg=#" . a:bg[0] . " ctermbg=" . a:bg[1]
  endif
  if a:attr != ""
    let l:args .= " gui=" . a:attr . " cterm=" . a:attr
  endif
  exec "hi" . l:args
endfun

" Vim
call <SID>HL("Normal",      s:bright_white,  s:black,        "")
call <SID>HL("LineNr",      s:bright_white,  s:bright_black, "")
call <SID>HL("VertSplit",   s:bright_black,  s:bright_black, "")
call <SID>HL("SignColumn",  s:bright_white,  s:bright_black, "")

call <SID>HL("StatusLine",    s:bright_white,  s:bright_black, "none")
call <SID>HL("StatusLineNC",  s:bright_black,  s:bright_white, "reverse,bold")

if version >= 700
  call <SID>HL("CursorLineNr", s:bright_yellow, s:bright_black,  "")
end

" Vim Omnicompletion (PMenu)
call <SID>HL("Pmenu",      s:bright_white,  s:bright_black,  "")
call <SID>HL("PmenuSel",   s:bright_cyan,   s:bright_black,  "bold")
" FIXME: What is it?
call <SID>HL("PmenuSbar",  s:bright_red,    s:bright_black,  "")
call <SID>HL("PmenuThumb", s:bright_red,    s:bright_black,  "")

" Text
call <SID>HL("Comment",     s:bright_black,   [], "")
call <SID>HL("Todo",        s:yellow,         [], "")
call <SID>HL("Title",       s:bright_black,   [], "")
call <SID>HL("Identifier",  s:cyan,           [], "")
call <SID>HL("Statement",   s:bright_white,   [], "")
call <SID>HL("Conditional", s:bright_purple,  [], "")
call <SID>HL("Repeat",      s:bright_purple,  [], "")
call <SID>HL("Structure",   s:bright_purple,  [], "")
call <SID>HL("Function",    s:blue,           [], "")
call <SID>HL("Constant",    s:yellow,         [], "")
call <SID>HL("String",      s:green,          [], "")
call <SID>HL("Special",     s:bright_blue,    [], "")
call <SID>HL("PreProc",     s:purple,         [], "")
call <SID>HL("Operator",    s:cyan,           [], "")
call <SID>HL("Type",        s:blue,           [], "")
call <SID>HL("Define",      s:purple,         [], "")
call <SID>HL("Include",     s:blue,           [], "")
               
" GitGutter
call <SID>HL("GitGutterAddDefault",       s:bright_green,   s:bright_black, "bold")
call <SID>HL("GitGutterChangeDefault",    s:bright_yellow,  s:bright_black, "bold")
call <SID>HL("GitGutterDeleteDefault",    s:bright_red,     s:bright_black, "bold")
call <SID>HL("GitGutterAddInvisible",     s:bright_black,   s:bright_black, "")
call <SID>HL("GitGutterChangeInvisible",  s:bright_black,   s:bright_black, "")
call <SID>HL("GitGutterDeleteInvisible",  s:bright_black,   s:bright_black, "")

" Syntastic
call <SID>HL("SyntasticErrorSign",          s:accent_red,     s:bright_black, "")
call <SID>HL("SyntasticWarningSign",        s:bright_yellow,  s:bright_black, "")
call <SID>HL("SyntasticStyleErrorSign",     s:bright_red,     s:bright_black, "")
call <SID>HL("SyntasticStyleWariningSign",  s:bright_purple,  s:bright_black, "")


delf <SID>HL
