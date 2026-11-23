#
# conf.d/010-tools.fish
#
# Syntax highlighting, autosuggestions and completions are built into fish.
# Each tool below is set up only if it's installed.
#

status is-interactive; or return

set -g fish_greeting

# fzf key bindings:
#   ctrl-t     insert files or folders (bat / eza tree preview)
#   alt-c      cd into a folder (eza tree preview)
#   ctrl-r     search history
#   shift-tab  pick from fish's completions, options once the word starts
#              with -; files get a preview
# ctrl-t and shift-tab show the command line being edited above the query.
if command -q fzf
    # --no-height overrides the 40% the widgets pass first: fzf covers the
    # whole window, like a kitty overlay, and puts the screen back when it
    # closes. base16 takes the terminal's colors, so fzf follows kitty's
    # catppuccin dark/light switch. The preview moves below the list when
    # it would be narrower than 50 columns; ctrl-/ hides it.
    set -gx FZF_DEFAULT_OPTS \
        "--style=minimal --no-height --layout=reverse --info=inline-right" \
        "--highlight-line --header-first --prompt='❯ '" \
        "--color=base16,hl:blue,hl+:blue,prompt:magenta,pointer:magenta,marker:green,info:bright-black,border:bright-black,header:blue" \
        "--preview-window='right,55%,border-left,<50(down,50%,border-top)'" \
        "--bind=ctrl-/:toggle-preview"

    # Widgets run previews in $SHELL, so these stay valid in sh and fish.
    # bat can't ask the terminal for its background from inside a preview
    # and would fall back to a dark theme; auto:system follows the macOS
    # appearance instead, which is what kitty's theme follows too.
    # eza's icons need a Nerd Font (conf.d/001-terminal.fish).
    set -l bat 'bat --theme=auto:system --color=always --style=numbers --line-range=:300'
    set -l icons never
    test "$nerd_font" = 1; and set icons always
    set -l tree "eza --tree --level=2 --all --ignore-glob=.git --color=always --icons=$icons"
    set -l preview_path "$bat {} 2>/dev/null || $tree {} 2>/dev/null"
    set -gx FZF_CTRL_T_OPTS "--preview='$preview_path'"
    set -gx FZF_ALT_C_OPTS "--preview='$tree {}'"
    set -gx FZF_EXPANSION_OPTS "--preview='$preview_path'"

    # Shift-tab runs fish. Candidates come escaped (My\ File) in field 1;
    # the preview shows up only for ones that exist on disk.
    set -gx FZF_COMPLETION_OPTS \
        "--preview='set -l f (string unescape -- {1}); $bat -- \$f 2>/dev/null; or $tree -- \$f 2>/dev/null'" \
        "--bind='start,focus:transform:test -e (string unescape -- {1}) 2>/dev/null; and echo show-preview; or echo hide-preview'"

    fzf --fish | source

    # functions/fzf-*-cmdline.fish wrap the widgets to add the header.
    bind ctrl-t fzf-file-widget-cmdline
    bind -M insert ctrl-t fzf-file-widget-cmdline
    bind shift-tab fzf-complete-cmdline
    bind -M insert shift-tab fzf-complete-cmdline
end
