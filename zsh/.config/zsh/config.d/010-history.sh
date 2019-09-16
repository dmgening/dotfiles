#!/usr/bin/env zsh
#
# conf.d/010-history.sh
#

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.

unsetopt HIST_BEEP               # Beep when accessing non-existent history.

#
# Variables
#

HISTFILE=$ZSH_CACHE_HOME/zhistory  # The path to the history file.
HISTSIZE=50000                     # The maximum number of events to save in the internal history.
SAVEHIST=50000                     # The maximum number of events to save in the history file.

#
# Plugins
#

zplugin ice wait"1" lucid
zplugin load zdharma/history-search-multi-word
zstyle ":history-search-multi-word" page-size "10"