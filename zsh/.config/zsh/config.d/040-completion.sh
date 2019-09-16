#!/usr/bin/env zsh
#
# conf.d/040-completion.sh
#

# Variables
comp_cache_dir=${ZSH_CACHE_HOME}/zcompcache
comp_extension=${ZSH_CACHE_HOME}/zcompext

# Options
setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
setopt PATH_DIRS           # Perform path search even on command names with slashes.
setopt AUTO_MENU           # Show completion menu on a successive tab press.
setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
setopt AUTO_PARAM_SLASH    # If completed parameter is a directory, add a trailing slash.
setopt EXTENDED_GLOB       # Needed for file modification glob modifiers with compinit

unsetopt MENU_COMPLETE     # Do not autoselect the first completion entry.
unsetopt FLOW_CONTROL      # Disable start/stop characters in shell editor.

# Inline suggestions
zplugin ice wait"1b" \
            lucid \
            atload"_zsh_autosuggest_start" \
            wrap-track"_zsh_autosuggest_start" \
zplugin load zsh-users/zsh-autosuggestions

# Extra completions
zplugin ice blockf
zplugin load zsh-users/zsh-completions

# Add externals zsh-completions to $fpath.
if [[ -d "$comp_extension" ]]; then
    fpath=($comp_extension $fpath)
fi
