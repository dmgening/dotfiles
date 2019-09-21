#
# Executes commands at the start of an interactive session.
#

# Set zplugin locations and settings
declare -A ZPLGM
ZPLGM[BIN_DIR]="$XDG_DATA_HOME/zplugin/bin"
ZPLGM[HOME_DIR]="$XDG_DATA_HOME/zplugin"
ZPLGM[ZCOMPDUMP_PATH]="$ZSH_CACHE_HOME/zcompdump"

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

# Load configs from config.d
for conf ($ZSH_CONFIG_HOME/config.d/*) source $conf

# Load run hooks from hooks
if [[ -d $ZSH_CONFIG_HOME/hooks ]] {
    for hook ($ZSH_CONFIG_HOME/hooks/*) source $hook
}