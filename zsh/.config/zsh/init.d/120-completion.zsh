#
# Variables
#

comp_dump_file=${ZDATADIR}/zcompdump
comp_cache_dir=${ZDATADIR}/zcompcache

#
# Init engine
#

autoload -U compinit
compinit -u -d $comp_dump_file

#
# General options
#

zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$comp_cache_dir"

#
# Load plugins
#

antibody bundle <<EOF
zsh-users/zsh-autosuggestions
zsh-users/zsh-completions
zsh-users/zsh-history-substring-search
EOF

#
# Configure plugins
#

## zsh-users/zsh-history-substring-search
export HISTORY_SUBSTRING_SEARCH_FUZZY=YES

# Cycle through history matches via arrow keys
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
