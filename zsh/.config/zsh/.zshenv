#
# Defines environment variables.
#

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
export PIPENV_MAX_DEPTH=15
export LESSHISTFILE="$XDG_DATA_HOME/lesshst"

export HELM_HOME="$XDG_DATA_HOME/helm"
export KUBECONFIG="$XDG_CONFIG_HOME/kube/config"

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprofile"
fi

export NVM_DIR="$HOME/.config"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
