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
    # The widget pastes FZF_CTRL_T_OPTS into fzf's options as text, so the
    # header gets backslash-escaped. An exported local reaches the widget.
    # nf-oct-terminal
    set -lx FZF_CTRL_T_OPTS $FZF_CTRL_T_OPTS --header=(string escape -n -- \uf489" $cmd")
    fzf-file-widget
end
