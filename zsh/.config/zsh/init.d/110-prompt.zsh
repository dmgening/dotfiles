#
# Load and configure prompt theme bundle
# 

SPACESHIP_CHAR_SUFFIX=" "
SPACESHIP_CHAR_SYMBOL="λ"
SPACESHIP_GIT_SYMBOL="🔀 "
SPACESHIP_DIR_LOCK_SYMBOL=" 🔒 "

#
# Disable emoji in prompt via env variable
#

if [[ -n "$PS_DISABLE_EMOJI" ]]; then
    SPACESHIP_DIR_LOCK_SYMBOL=" [locked] "
    SPACESHIP_JOBS_SYMBOL="[jobs] "
    SPACESHIP_EXIT_CODE_SYMBOL="[exit] "

    SPACESHIP_GIT_SYMBOL="(git) "
    SPACESHIP_HG_SYMBOL="(hg) "
    SPACESHIP_PACKAGE_SYMBOL="(pkg) "
    SPACESHIP_NODE_SYMBOL="(node) "
    SPACESHIP_RUBY_SYMBOL="(ruby) "
    SPACESHIP_ELM_SYMBOL="(elm) "
    SPACESHIP_ELIXIR_SYMBOL="(elixir) "
    SPACESHIP_XCODE_SYMBOL="(xcode) "
    SPACESHIP_SWIFT_SYMBOL="(swift) "
    SPACESHIP_GOLANG_SYMBOL="(golang) "
    SPACESHIP_PHP_SYMBOL="(php) "
    SPACESHIP_RUST_SYMBOL="(rust) "
    SPACESHIP_HASKELL_SYMBOL="(haskell) "
    SPACESHIP_JULIA_SYMBOL="(julia) "
    SPACESHIP_DOCKER_SYMBOL="(docker) "
    SPACESHIP_AWS_SYMBOL="(aws) "
    SPACESHIP_VENV_SYMBOL="(venv) "
    SPACESHIP_CONDA_SYMBOL="(conda) "
    SPACESHIP_PYENV_SYMBOL="(pyenv) "
    SPACESHIP_DOTNET_SYMBOL="(.net) "
    SPACESHIP_EMBER_SYMBOL="(ember.js) "
    SPACESHIP_KUBECONTEXT_SYMBOL="(k8s) "
    SPACESHIP_TERRAFORM_SYMBOL="(terraform) "
fi

antibody bundle <<EOF
denysdovhan/spaceship-prompt
zdharma/fast-syntax-highlighting
EOF
