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
path=($XDG_BIN_HOME /opt/homebrew/{bin,sbin} /usr/local/{bin,sbin} $path)
fpath=($ZSH_CONFIG_HOME/functions ${fpath[@]})

# Set zinit locations and settings
declare -A ZINIT
ZINIT[BIN_DIR]="$XDG_DATA_HOME/zinit/bin"
ZINIT[HOME_DIR]="$XDG_DATA_HOME/zinit"
ZINIT[PLUGINS_DIR]="$ZSH_CONFIG_HOME/plugins"
# ZINIT[COMPLETIONS_DIR]=
# ZINIT[SNIPPETS_DIR]=
ZINIT[ZCOMPDUMP_PATH]="$ZSH_CACHE_HOME/zcompdump"
# ZINIT[COMPINIT_OPTS]=
# ZINIT[MUTE_WARNINGS]=

# Check if zinit installed or install it from github
if [[ ! -d $ZINIT[BIN_DIR] ]] {
    (
        export ZINIT_HOME=$ZINIT[HOME_DIR];
        mkdir -p "$(dirname $ZINIT[BIN_DIR])"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT[BIN_DIR]"
    )
}

# Init zinit
source $ZINIT[BIN_DIR]/zinit.zsh

# Load local user secrets
if [[ -a $ZSH_CONFIG_HOME/secrets.sh ]] {
    source $ZSH_CONFIG_HOME/secrets.sh
} 

# Load configs from conf.d
for conf ("${(f)$(ls $ZSH_CONFIG_HOME/config.d/*(.))}") {
    source $conf
}
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
### End of Zinit's installer chunk
