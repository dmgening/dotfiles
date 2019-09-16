#
# Executes commands at login pre-zshrc.
#

#
# Language
#

# [[ -z "$LANG" ]] && export LANG='en_US.UTF-8'

#
# Paths
#

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that cd searches.
cdpath=(
    $HOME
    $cdpath
)

# Set the list of directories that Zsh searches for programs.
path=(
    $XDG_BIN_HOME
    /usr/local/{bin,sbin}
    $path
)

#
# Editors
#

if [[ -f "$(which emacsclient)" ]]; then 
    export EDITOR="$(which emacsclient) -nw"
elif [[ -f "$(which vim)" ]]; then 
    export EDITOR="$(which vim)"
else 
    export EDITOR="$(which nano)"
fi

export VISUAL="$EDITOR"
export PAGER='less'

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
# export LESS='-F -g -i -M -R -S -w -X -z-4'

#
# Load local overrides
#

for file in $(find $ZDOTDIR -iname '.zprofile*.local'); do
    source $file
done