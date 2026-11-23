#
# functions/fzf-file-widget-cmdline.fish
#
# Ctrl-t: fzf's fzf-file-widget with the command line being edited as the
# header, so the query isn't all you see. Bound in conf.d/010-tools.fish.
#

function fzf-file-widget-cmdline --description 'fzf-file-widget with the command line as header'
    set -l cmd (commandline -b | string join ' ')
    if test -z "$cmd"
        fzf-file-widget
        return
    end
    # nf-oct-terminal, or $ without a Nerd Font.
    set -l icon '$'
    test "$nerd_font" = 1; and set icon 
    # The widget pastes FZF_CTRL_T_OPTS into fzf's options as text, so the
    # header gets backslash-escaped. An exported local reaches the widget.
    set -lx FZF_CTRL_T_OPTS $FZF_CTRL_T_OPTS --header=(string escape -n -- "$icon $cmd")
    fzf-file-widget
end
