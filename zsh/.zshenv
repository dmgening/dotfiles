#
# Defines config and data directories paths.
#

#
# Opendesktop base directories
#

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.local/cache"
export XDG_BIN_HOME="$HOME/.local/bin"

#
# Zsh base directories
#

test -z "$ZDOTDIR" && export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
test -z "$ZDATADIR" && export ZDATADIR="$XDG_DATA_HOME/zsh"

#
# Source extra zshenv if exists
#

test -f "$ZDOTDIR/.zshenv" && source "$ZDOTDIR/.zshenv"

