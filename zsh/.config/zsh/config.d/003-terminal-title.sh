#!/usr/bin/env zsh

# Set terminal title for tmux/kitty window naming
# precmd: idle prompt shows current directory
# preexec: running command shows command name

function _set_title() { printf '\e]0;%s\a' "$1" }

function precmd_title() { _set_title "${PWD##*/}" }
function preexec_title() { _set_title "${1%% *}" }

autoload -Uz add-zsh-hook
add-zsh-hook precmd precmd_title
add-zsh-hook preexec preexec_title
