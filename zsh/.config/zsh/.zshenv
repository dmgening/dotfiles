#
# Defines environment variables.
#

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
export LESSHISTFILE="$XDG_DATA_HOME/lesshst"

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprofile"
fi
