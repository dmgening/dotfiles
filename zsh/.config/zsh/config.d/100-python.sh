#!/usr/bin/env zsh
#
# conf.d/100-python.sh
#

# Return if requirements are not found.
if (( ! $+commands[python] )); then
    return 1
fi

# Setup pyenv
function () {
    # Return if requirements are not found.
    if (( ! $+commands[pyenv] )); then
        return 1
    fi

    # Retrieve pyenv configuration and plugins
    local data_dir=${PYENV_ROOT:-${XDG_DATA_HOME}/pyenv}
    local -a plugins=(${(@oM)${(f)"$(pyenv commands --no-sh 2>/dev/null)"}:#virtualenv*})
    local -a init_plugins=(virtualenv)

    # Export changes
    export VIRTUAL_ENV_DISABLE_PROMPT=12
    export PYENV_ROOT="${data_dir}"

    # Load pyenv and plugins
    eval "$(pyenv init - --no-rehash zsh)"
    for plugin in $init_plugins; do
        if (( $plugins[(i)${plugin}-init] <= $#plugins )); then
            eval "$(pyenv ${plugin}-init - zsh)"
        fi
    done
}

export POETRY_HOME=${POETRY_HOME:-${XDG_DATA_HOME}/poetry}
export PATH=${POETRY_HOME}/bin:$PATH
