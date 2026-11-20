#
# conf.d/010-tools.fish
#
# Syntax highlighting, autosuggestions and completions are built into fish.
# Each tool below is set up only if it's installed.
#

status is-interactive; or return

set -g fish_greeting

# fzf: ctrl-t inserts a file, alt-c cds into a directory, ctrl-r searches
# history. atuin comes after it, so it takes over ctrl-r once installed.
command -q fzf; and fzf --fish | source
command -q atuin; and atuin init fish | source
