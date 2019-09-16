#
# Executes commands at the start of an interactive session.
#

#
# Load plugin files from $ZDOTDIR/plugins in order
#

for file in $ZDOTDIR/plugins/**/*(.); do
    source $file
done

#
# Load local overrides
#

for file in $(find $ZDOTDIR -iname '.zshrc*.local'); do
    source $file
done