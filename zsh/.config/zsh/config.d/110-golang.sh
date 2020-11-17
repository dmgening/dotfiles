#!/usr/bin/env zsh
#
# conf.d/110-golang.sh
#

# Return if requirements are not found.
#if (( ! $+commands[go] )); then
#    return 1
#fi

function () {
    local src="$XDG_DATA_HOME/gvm/scripts/gvm" 
    if [[ -f $src ]]; then
        source $src
    fi
}