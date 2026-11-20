#
# functions/fish_right_prompt.fish
#
#    2  1m 5s  14:02
#
# Background jobs, how long the last command took (when it ran 2s or
# longer), and the clock. Icons are Nerd Font glyphs, written as escapes.
#

function fish_right_prompt --description 'Background jobs, last command duration, clock'
    # nf-fa-cog
    set -l njobs (count (jobs -g))
    if test $njobs -gt 0
        set_color blue
        echo -n " $njobs "
    end

    # nf-fa-hourglass_half
    if set -q CMD_DURATION; and test $CMD_DURATION -ge 2000
        set -l s (math "floor($CMD_DURATION / 1000)")
        set -l parts
        test $s -ge 3600; and set -a parts (math "floor($s / 3600)")h
        test $s -ge 60; and set -a parts (math "floor($s % 3600 / 60)")m
        set -a parts (math "$s % 60")s
        set_color yellow
        echo -n ' '(string join ' ' $parts)' '
    end

    # nf-fa-clock
    set_color brblack
    echo -n ' '(date +%H:%M)
    set_color normal
end
