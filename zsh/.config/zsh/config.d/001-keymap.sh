#!/usr/bin/env zsh
#
# conf.d/001-keymap.sh
#

zmodload zsh/terminfo
typeset -gA key_info K_MODS

K_MODS=(
    'C-'   '\C-'
    'M-'   '\M-'
    'ESC'  '\e'
)

key_info=(
  'Control'         '\C-'
  'ControlLeft'     '\e[1;5D \e[5D \e\e[D \eOd'
  'ControlRight'    '\e[1;5C \e[5C \e\e[C \eOc'
  'ControlPageUp'   '\e[5;5~'
  'ControlPageDown' '\e[6;5~'
  'Escape'          '\e'
  'Meta'            '\M-'
  'Backspace'       "^?"
  'Delete'          "^[[3~"
  'F1'              "$terminfo[kf1]"
  'F2'              "$terminfo[kf2]"
  'F3'              "$terminfo[kf3]"
  'F4'              "$terminfo[kf4]"
  'F5'              "$terminfo[kf5]"
  'F6'              "$terminfo[kf6]"
  'F7'              "$terminfo[kf7]"
  'F8'              "$terminfo[kf8]"
  'F9'              "$terminfo[kf9]"
  'F10'             "$terminfo[kf10]"
  'F11'             "$terminfo[kf11]"
  'F12'             "$terminfo[kf12]"
  'Insert'          "$terminfo[kich1]"
  'Home'            "$terminfo[khome]"
  'PageUp'          "$terminfo[kpp]"
  'End'             "$terminfo[kend]"
  'PageDown'        "$terminfo[knp]"
  'Up'              "$terminfo[kcuu1]"
  'Left'            "$terminfo[kcub1]"
  'Down'            "$terminfo[kcud1]"
  'Right'           "$terminfo[kcuf1]"
  'BackTab'         "$terminfo[kcbt]"
)

# Set empty $key_info values to an invalid UTF-8 sequence to induce silent
# bindkey failure.
for key in "${(k)key_info[@]}"; do
  if [[ -z "$key_info[$key]" ]]; then
    key_info[$key]='�'
  fi
done