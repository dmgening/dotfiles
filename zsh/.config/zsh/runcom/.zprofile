#
# Executes commands at login pre-zshrc.
#

# mise shims, so scripts and IDE-spawned shells see the runtimes too.
# Interactive shells switch to `mise activate` in config.d/100-mise.sh.
if [[ -x /opt/homebrew/bin/mise ]]; then
  eval "$(/opt/homebrew/bin/mise activate zsh --shims)"
fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
