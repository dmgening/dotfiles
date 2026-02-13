#!/usr/bin/env zsh
#
# conf.d/990-alias.sh
#

# Disable correction.
alias ack='nocorrect ack'
alias cd='nocorrect cd'
alias cp='nocorrect cp'
alias ebuild='nocorrect ebuild'
alias gcc='nocorrect gcc'
alias gist='nocorrect gist'
alias grep='nocorrect grep'
alias heroku='nocorrect heroku'
alias ln='nocorrect ln'
alias man='nocorrect man'
alias mkdir='nocorrect mkdir'
alias mv='nocorrect mv'
alias mysql='nocorrect mysql'
alias rm='nocorrect rm'

# Disable globbing.
alias bower='noglob bower'
alias fc='noglob fc'
alias find='noglob find'
alias ftp='noglob ftp'
alias history='noglob history'
alias locate='noglob locate'
alias rake='noglob rake'
alias rsync='noglob rsync'
alias scp='noglob scp'
alias sftp='noglob sftp'

# Safe ops. Ask the user before doing anything destructive.
if [[ -z "$DISABLE_SAFEOPS_ALIASES" ]]; then
    alias rm="${aliases[rm]:-rm} -i"
    alias mv="${aliases[mv]:-mv} -i"
    alias cp="${aliases[cp]:-cp} -i"
    alias ln="${aliases[ln]:-ln} -i"
fi

# Modern CLI tool aliases
alias ls='eza --icons --git'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'

# Default options
alias mkdir="${aliases[mkdir]:-mkdir} -p"
alias df='df -kh'
alias du='du -kh'

# Convenient shortcuts using eza
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza --tree --icons --git'
alias l='eza --icons --git'
