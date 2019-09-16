#
# Executes commands at logout.
#

#
# Load local overrides
#

for file in $(find $ZDOTDIR -iname '.zlogout*.local'); do
    source $file
done