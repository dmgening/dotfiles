#
# conf.d/990-alias.fish
#
# alias replaces a command; abbr expands as you type,
# so history keeps the full command.
#

status is-interactive; or return

if command -q eza
    alias ls 'eza --icons --git'
    abbr -a ll 'eza -l --icons --git'
    abbr -a la 'eza -la --icons --git'
    abbr -a lt 'eza --tree --icons --git'
end
command -q bat; and alias cat 'bat --paging=never'
