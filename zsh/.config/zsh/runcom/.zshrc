#
# Executes commands at the start of an interactive session.
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
fpath=($ZSH_CONFIG_HOME/functions ${fpath[@]})

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

# Check if zplugin installed or install it from github
if [[ ! -d $ZPLGM[BIN_DIR] ]] {
    (
        export ZPLG_INSTALL_URL="https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh";
        export ZPLG_HOME=$ZPLGM[HOME_DIR];
        curl -fsSL $ZPLG_INSTALL_URL | zsh 
    )
}

# Init zplugin
source $ZPLGM[BIN_DIR]/zplugin.zsh

# Load local user config
if [[ -a $ZSH_HOME_DIR/config.sh ]] {
    source $ZSH_HOME_DIR/config.sh
} 

# Load configs from conf.d
for conf ("${(f)$(ls $ZSH_CONFIG_HOME/config.d/*(.))}") {
    source $conf
}
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
