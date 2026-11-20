#!/usr/bin/env zsh
#
# conf.d/100-mise.sh
#
# Runtimes (node, python, go, uv, pnpm) come from mise: global versions in
# ~/.config/mise/config.toml, per-project ones in mise.toml. Updates PATH on
# every prompt; non-interactive shells get mise's shims from .zprofile.
#

# Return if requirements are not found.
if (( ! $+commands[mise] )); then
    return 1
fi

eval "$(mise activate zsh)"
