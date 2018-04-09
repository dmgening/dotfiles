#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Update CWD inside emacs term emulators
if [ -n "$INSIDE_EMACS" ]; then
    # function to set the dired and host for ansiterm
    set_eterm_dir() {
        print -P "\033AnSiTu %n"
        print -P "\033AnSiTh" "$(hostname -f)"
        print -P "\033AnSiTc %d"
    }

    # call prmptcmd whenever prompt is redrawn
    precmd_functions=($precmd_functions set_eterm_dir)
fi
