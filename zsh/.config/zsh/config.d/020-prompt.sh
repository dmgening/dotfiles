#!/usr/bin/env zsh
#
# conf.d/020-prompt.sh
#

# Theme
zplugin ice use"spaceship.zsh"
zplugin load denysdovhan/spaceship-prompt 

# Syntax highlight
zplugin ice wait"0" \
            atinit"zpcompinit; zpcdreplay"
zplugin load zdharma/fast-syntax-highlighting

# Output colorization
zplugin ice wait"0"
zplugin load unixorn/warhol.plugin.zsh

# Man page colorization
zplugin ice wait"0"
zplugin load ael-code/zsh-colored-man-pages