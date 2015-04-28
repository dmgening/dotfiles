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

fun <SID>HL(group, fg, bg, attr)
  let l:args = " " . a:group
  if a:fg != []
    let l:args .= " guifg=" . a:fg[0] . " ctermfg=" . a:fg[1]
  endif
  if a:bg != []
    let l:args .= " guibg=" . a:bg[0] . " ctermbg=" . a:bg[1]
  endif
  if a:attr != ""
    let l:args .= " gui=" . a:attr . " cterm=" . a:attr
  endif
  exec "hi" . l:args
endfun

call <SID>HL("Normal",    s:bright_white,  s:black,         "")
call <SID>HL("LineNr",    s:bright_white,  s:bright_black,  "")
call <SID>HL("VertSplit", s:bright_black,  s:bright_black,  "")

if version >= 700
  call <SID>HL("CursorLineNr", s:bright_yellow, s:bright_black,  "")
end

delf <SID>HL
