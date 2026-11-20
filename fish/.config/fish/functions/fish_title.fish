#
# functions/fish_title.fish
#
# Short terminal titles for tmux window names (automatic-rename-format
# "#{pane_title}") and kitty tabs: the idle prompt shows the current directory,
# a running command shows its name. fish's default adds the path to both.
#

function fish_title
    set -l cmd (string trim -- "$argv[1]")
    if test -n "$cmd"
        string split -f1 ' ' -- $cmd
    else
        path basename -- $PWD
    end
end
