#
# Executes commands at the start of an interactive session.
#

#
# Load plugin files from $ZDOTDIR/init.d in order
#
CONFIG_FILE="$ZDOTDIR/config.zsh"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

for file in $ZDOTDIR/init.d/*.zsh; do
    source $file
done
