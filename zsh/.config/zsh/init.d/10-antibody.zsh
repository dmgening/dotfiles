#
# Install and init antibody zsh plugin manager
#

ANTIBODY="$XDG_BIN_HOME/antibody"
if [ ! -e "$ANTIBODY" ]; then
    echo "Missing antibody zsh package manager. Trying to fetch installer"
    curl -sfL git.io/antibody | sh -s - -b $XDG_BIN_HOME
fi

source <(antibody init)