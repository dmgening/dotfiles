#
# Defines config and data directories paths.
#

# Opendesktop base directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.local/cache"
export XDG_BIN_HOME="$HOME/.local/bin"

# Zsh base directories
export ZSH_CONFIG_HOME="$XDG_CONFIG_HOME/zsh"
export ZSH_CACHE_HOME="$XDG_CACHE_HOME/zsh"
export ZDOTDIR="$ZSH_CONFIG_HOME/runcom"

# Source extra zshenv if exists
test -f "$ZDOTDIR/.zshenv" && source "$ZDOTDIR/.zshenv"

