#
# functions/fish_prompt.fish
#
#   ~/P/p/dotfiles  master* ⇡  proj ❯
#
# ANSI color names, so the prompt follows kitty's catppuccin dark/light
# switch. Icons are Nerd Font glyphs, written as escapes. Git settings
# live in conf.d/020-prompt.fish.
#

function fish_prompt --description 'Minimal one-line prompt'
    # Must come first: any command below overwrites $status.
    set -l last_status $status

    # nf-md-ssh
    if set -q SSH_TTY
        set_color brblack
        echo -n \U000f08c0' '(prompt_hostname)' '
    end

    set_color blue
    echo -n (prompt_pwd)

    # nf-oct-git_branch. One * per kind of change comes out of
    # fish_git_prompt; keep one.
    set_color brblack
    echo -n (fish_git_prompt ' '\uf418' %s' | string replace -r '\*+' '*')

    if set -q VIRTUAL_ENV
        # VIRTUAL_ENV_PROMPT holds the project name for venv and uv
        # ("(name) " in older Pythons). Without it, as with mise, use the
        # directory, or its parent when it's just .venv.
        set -l venv (string trim -c '() ' -- "$VIRTUAL_ENV_PROMPT")
        if test -z "$venv"
            set venv (path basename $VIRTUAL_ENV)
            contains -- $venv .venv venv
            and set venv (path basename (path dirname $VIRTUAL_ENV))
        end
        # nf-dev-python
        set_color brblack
        echo -n ' '\ue73c" $venv"
    end

    test $last_status -eq 0
    and set_color magenta
    or set_color red
    echo -n ' ❯ '
    set_color normal
end
