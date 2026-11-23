#
# conf.d/001-terminal.fish
#
# What the terminal can do, for the files that come after this one.
#

status is-interactive; or return

# The Claude desktop terminal doesn't answer fish's startup queries, so
# fish waits 10 seconds and warns. Turning off the query-term feature
# flag stops the queries, but fish reads it only at startup: start over
# with it set. fish sends them after config, so the first run sends none.
if test "$TERM_PROGRAM" = claude-desktop
    and not contains no-query-term (string split , -- $fish_features)
    set -l login
    status is-login; and set login --login
    exec env fish_features=(string join , -- $fish_features no-query-term) (status fish-path) $login
end

# Nerd Font icons only where the font is known to have them: kitty uses
# MesloLGS Nerd Font. Elsewhere, such as the Claude desktop terminal,
# plain text. To override, run once: set -U nerd_font 1 (or 0).
if not set -q nerd_font
    if test "$TERM" = xterm-kitty; or set -q KITTY_WINDOW_ID
        set -g nerd_font 1
    else
        set -g nerd_font 0
    end
end
