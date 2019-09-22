#!/usr/local/env zsh



#
# Template language helper
#

function _wrap       { if [[ -n "${@:2}" ]]; echo "$1${@:2}$1" }
function _var        { if [[ -n "$1" ]]; echo "#{$1}" }
function _style      { if [[ -n "$1" ]]; echo "#[$1]" }

function _trim       { echo $(_var "=$1:$2")}
function _operator   { echo "#{$1${(j:,:)@:2}}" }
function _if         { echo "$(_operator '?' $1 ${2:-''} ${3:-''})" }
function _or         { echo "$(_operator '||:' $1 $2)" }
function _and        { echo "$(_operator '&&:' $1 $2)" }
function _eq         { echo "$(_operator '==:' $1 $2)" }

function _fg_bare    { echo "fg=${(j:,:)@}" }
function _bg_bare    { echo "bg=${(j:,:)@}" }
function _fg         { echo "$(_style $(_fg_bare $@))" }
function _bg         { echo "$(_style $(_bg_bare $@))" }

function _reset      { echo "$(_style $(_fg_bare default none),$(_bg_bare default none))" }

typeset -A C=(
    black   colour0 brightBlack   colour8
    red     colour1 brightRed     colour9
    green   colour2 brightGreen   colour10
    yellow  colour3 brightYellow  colour11
    blue    colour4 brightBlue    colour12
    magenta colour5 brightMagenta colour13
    cyan    colour6 brightCyan    colour14
    white   colour7 brightWhite   colour15
)

#
# Status lines
#

typeset -a WS_ACTIVITY=('?' 'window_activity_flag' $(_fg_bare ${C[yellow]}))
typeset -a WS_ACTIVE=('+' 'window_active' $(_fg_bare ${C[green]}))
typeset -a WS_BELL=('!' 'window_bell_flag' $(_fg_bare ${C[red]}))
typeset -a WS_ZOOMED=('z' 'window_zoomed_flag')
typeset -a WS_LAST=('=' 'window_last_flag')
typeset -a WINDOW_STATUS_TOKEN=('$WS_ACTIVITY' '$WS_ACTIVE' '$WS_BELL' '$WS_ZOOMED' '$WS_LAST')

function window-status-format {
    local index="$(_var window_index)"
    local name="$(_style "$(_if window_active $(_fg_bare ${C[green]} bright))")$(_trim 20 window_name)$(_fg default none)"
    local -a styles=() tokens=()

    for row (${(@)WINDOW_STATUS_TOKEN}) {
        local refrow=(${(e)row})
        local token=${refrow[1]} flag=${refrow[2]} style=${refrow[3]}
        [[ -n "${style}" ]] && styles+=("$(_if $(_var $flag) $(_style $style))")
        tokens+=("$(_if $(_var $flag) ${token})")
    }

    local result="(${index}:${name}$(_reset)${(j::)styles}$(_if "${(j::)tokens}" "[${(j::)tokens}]"))"
    echo $(_wrap $(_reset) ${result})
}


function status-left-format {
    local session="Session $(_fg ${C[green]})$(_var session_name)$(_reset)"
    local hostname=" on $(_fg ${C[cyan]})$(_var host)$(_reset)"
    local result="${session}${hostname} running"
    echo "$(_wrap $(_reset) ${result}) "
}


function status-right-format {
    local watch="#(date '+ $(_fg ${C[white]} dim) %Y-%m-%d $(_fg ${C[brightWhite]} bold)%H:%M')"
    local result="${watch}"
    echo " $(_wrap $(_reset) ${result})"
}

#
#
#

tmux set -g window-status-format         "$(window-status-format)" \;\
     set -g window-status-current-format "$(window-status-format)" \;\
     set -g window-status-separator      " "                       \;\
     set -g status-left                  "$(status-left-format)"   \;\
     set -g status-left-length           40                        \;\
     set -g status-right                 "$(status-right-format)"  \;\
     set -g status-right-length          40                        \;\
     set -g status-justify               left                      \;\
     set -g status-position              top                       \;\
     set -g status-bg                    default                   \;\
     set -g status-fg                    default

