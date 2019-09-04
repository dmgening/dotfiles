#
# Defines config and data directories paths.
#

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.local/cache"
export XDG_BIN_HOME="$HOME/.local/bin"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

source "$ZDOTDIR/.zshenv"
