
# Set default pyenv path
if [[ -z "$PYENV_ROOT" ]]; then
    PYENV_ROOT="$XDG_DATA_HOME/pyenv"
fi

# Check if pyenv exists
if [[ ! -d "$PYENV_ROOT" ]]; then
    return 1
fi

#
# Export root path
#

export PYENV_ROOT=$PYENV_ROOT

#
# Extend path
#

path=($PYENV_ROOT/bin $path)
export PATH

#
# Load pyenv
#

eval "$(pyenv init -)"

#
# Load pyenv-virtualenv plugin if installed
#

if [[ -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]]; then
    eval "$(pyenv virtualenv-init -)"
fi