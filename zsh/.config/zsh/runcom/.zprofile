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

# Set zplugin locations and settings
declare -A ZPLGM
ZPLGM[BIN_DIR]="$XDG_DATA_HOME/zplugin/bin"
ZPLGM[HOME_DIR]="$XDG_DATA_HOME/zplugin"
ZPLGM[PLUGINS_DIR]="$ZSH_CONFIG_HOME/plugins"
# ZPLGM[COMPLETIONS_DIR]=
# ZPLGM[SNIPPETS_DIR]=
ZPLGM[ZCOMPDUMP_PATH]="$ZSH_CACHE_HOME/zcompdump"
# ZPLGM[COMPINIT_OPTS]=
# ZPLGM[MUTE_WARNINGS]=