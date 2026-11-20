#
# conf.d/000-env.fish
#
# Every fish, scripts included. mise needs nothing here: Homebrew's
# vendor_conf.d/mise-activate.fish turns it on by itself.
#

# First entry wins; directories that don't exist are skipped.
# -P edits $PATH itself instead of the universal fish_user_paths,
# -m moves entries inherited from a parent shell to the front.
fish_add_path -Pm $HOME/.local/bin /opt/homebrew/bin /opt/homebrew/sbin $HOME/.orbstack/bin

command -q nvim; and set -gx EDITOR nvim

# bat's themes for a dark and a light background: the same catppuccin
# flavors kitty switches between.
set -gx BAT_THEME_DARK 'Catppuccin Macchiato'
set -gx BAT_THEME_LIGHT 'Catppuccin Latte'
