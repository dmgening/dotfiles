#
# conf.d/990-alias.fish
#
# alias replaces a command; abbr expands as you type,
# so history keeps the full command.
#

status is-interactive; or return

if command -q eza
    # Icons need a Nerd Font (conf.d/001-terminal.fish).
    set -l eza eza --git
    test "$nerd_font" = 1; and set -a eza --icons
    alias ls "$eza"
    abbr -a ll "$eza -l"
    abbr -a la "$eza -la"
    abbr -a lt "$eza --tree"
end
command -q bat; and alias cat 'bat --paging=never'
