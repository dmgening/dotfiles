#!/usr/bin/env zsh
#
# conf.d/020-prompt.sh
#

# Theme - Starship
# Starship is initialized via eval in .zshrc or a dedicated starship config
# See: config.d/021-prompt-starship.sh

# Syntax highlight
zinit ice wait"0" \
            atinit"zpcompinit; zpcdreplay"
zinit load zdharma-continuum/fast-syntax-highlighting