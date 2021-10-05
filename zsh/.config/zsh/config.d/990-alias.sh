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

# Default options
alias ls="${aliases[ls]:-ls}"                  # Colorized outuput
alias mkdir="${aliases[mkdir]:-mkdir} -p"                               # Create missing parent folders
alias df='df -kh'                                                       # Space usage in human readable format by kilobytes.
alias du='du -kh'                                                       # Same for folder

# Convinient shortcuts
alias ll="${aliases[ls]:-ls} -lh"        # Lists human readable sizes.
alias la="${aliases[ls]:-ls} -A"         # Lists human readable sizes, hidden files.
