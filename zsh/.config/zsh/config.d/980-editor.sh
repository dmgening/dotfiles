#!/usr/bin/env zsh
#
# conf.d/980-editor.sh
#

if (( $+commands[nvim] )); then
    export EDITOR=nvim
fi