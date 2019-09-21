#!/usr/bin/env zsh
#
# hooks/alias-tmux
#

alias tmux="${aliases[tmux]:-tmux} -f $XDG_CONFIG_HOME/tmux/tmux.conf"