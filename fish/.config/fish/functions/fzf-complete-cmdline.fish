#
# functions/fzf-complete-cmdline.fish
#
# Shift-tab: fzf's fzf_complete with the command line being edited as the
# header, so the query isn't all you see. Bound in conf.d/010-tools.fish.
#

function fzf-complete-cmdline --description 'fzf_complete with the command line as header'
    set -l cmd (commandline -b | string join ' ')
    if test -z "$cmd"
        fzf_complete
        return
    end
    # fzf_complete escapes its arguments and passes them on to fzf.
    # nf-oct-terminal
    fzf_complete --header=\uf489" $cmd"
end
