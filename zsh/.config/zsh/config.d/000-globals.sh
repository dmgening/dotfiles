#!/usr/bin/env zsh
#
# conf.d/000-globals.sh
#

# Options
setopt COMBINING_CHARS      # Combine zero-length punctuation characters (accents)
                            # with the base character.
setopt INTERACTIVE_COMMENTS # Enable comments in interactive shell.
setopt RC_QUOTES            # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'.

unsetopt MAIL_WARNING       # Don't print a warning message if a mail file has been accessed.
unsetopt BEEP               # Don't beep on zsh errors

# Enable full color on termcap
zplugin light chrissicool/zsh-256color

# Source LS_COLORS
zplugin ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
            atpull'%atclone' \
            pick"clrs.zsh" \
            nocompile'!' \
            atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
zplugin light trapd00r/LS_COLORS