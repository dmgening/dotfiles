#
# functions/fish_prompt.fish
#
#   ~/P/p/dotfiles  master* ⇡  proj ❯
#
# Without a Nerd Font (see conf.d/001-terminal.fish) the icons give way
# to plain text:
#
#   ~/P/p/dotfiles master* ⇡ (proj) ❯
#
# When that takes more than half the window, as in a worktree with a long
# path and branch, ❯ moves to a line of its own:
#
#   ~/P/p/dotfiles/.claude/worktrees/fish-prompt-wrap  claude/fish-prompt-wrap*
#   ❯
#
# ANSI color names, so the prompt follows kitty's catppuccin dark/light
# switch. Icons are Nerd Font glyphs, written as escapes. Git settings
# live in conf.d/020-prompt.fish.
#

function fish_prompt --description 'Minimal prompt, on two lines when it gets long'
    # Must come first: any command below overwrites $status.
    set -l last_status $status

    set -l ssh_fmt '@%s '
    set -l git_fmt ' %s'
    set -l venv_fmt ' (%s)'
    if test "$nerd_font" = 1
        set ssh_fmt \U000f08c0' %s ' # nf-md-ssh
        set git_fmt ' '' %s' # nf-oct-git_branch
        set venv_fmt ' '' %s' # nf-dev-python
    end

    # Everything before the prompt character, as colored pieces.
    set -l info

    set -q SSH_TTY
    and set -a info (set_color brblack)(printf $ssh_fmt (prompt_hostname))

    set -a info (set_color blue)(prompt_pwd)

    # One * per kind of change comes out of fish_git_prompt; keep one.
    set -l git (fish_git_prompt $git_fmt | string replace -r '\*+' '*')
    test -n "$git"
    and set -a info (set_color brblack)$git

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
        set -a info (set_color brblack)(printf $venv_fmt $venv)
    end

    set info (string join '' -- $info)
    echo -n $info

    # Leave at least half the window for the command; past that, the
    # prompt character starts a new line. fish redraws on resize.
    set -l char ' ❯ '
    if test (math (string length --visible -- $info) '* 2') -gt $COLUMNS
        echo
        set char '❯ '
    end

    test $last_status -eq 0
    and set_color magenta
    or set_color red
    echo -n $char
    set_color normal
end
