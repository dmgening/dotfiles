#
# Executes commands at login pre-zshrc.
#

# Ensure correct file creation permission
umask 022

# Ensure zsh cache path
[[ ! -d  $ZSH_CACHE_HOME ]] && mkdir -p $ZSH_CACHE_HOME

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that cd searches.
cdpath=($HOME $cdpath)

# Set the list of directories that Zsh searches for programs.
path=($XDG_BIN_HOME /usr/local/{bin,sbin} $path)
