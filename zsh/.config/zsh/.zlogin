#
# Executes commands at login post-zshrc.
#

#
# load local overrides
#

for file in $(find $ZDOTDIR -iname '.zlogin*.local'); do
    source $file
done