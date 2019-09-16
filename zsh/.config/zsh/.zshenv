#
# Defines environment variables.
#

#
# Load local overrides
#

for file in $(find $ZDOTDIR -iname '.zshenv*.local'); do
    source $file
done