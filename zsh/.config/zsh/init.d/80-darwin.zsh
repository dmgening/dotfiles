#
# Load OS X specific settings
#

if [[ "$OSTYPE" != darwin* ]]; then
    return 1
fi


#
# BSD ls config
#

alias ls="ls -GF"

if [[ -z "$LSCOLORS" ]]; then
    export LSCOLORS='exfxcxdxbxGxDxabagacad'
fi

# Define colors for the completion system if they're not already defined
if [[ -z "$LS_COLORS" ]]; then
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:sg=36;40;07:tw=32;40;07:ow=33;40;07:'
fi

#
#
#