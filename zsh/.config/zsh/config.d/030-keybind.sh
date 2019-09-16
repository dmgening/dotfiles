#!/usr/bin/env zsh
#
# conf.d/30-keybind.sh
#

# Treat these characters as part of a word.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

# Allow command line editing in an external editor.
autoload -Uz edit-command-line
zle -N edit-command-line

# Set emacs key bindings
bindkey -e

for key in "$key_info[Escape]"{B,b} \
           "${(s: :)key_info[ControlLeft]}" \
            "${key_info[Escape]}${key_info[Left]}"
  bindkey -M emacs "$key" emacs-backward-word

for key in "$key_info[Escape]"{F,f} \
           "${(s: :)key_info[ControlRight]}" \
           "${key_info[Escape]}${key_info[Right]}"
  bindkey -M emacs "$key" emacs-forward-word

# Kill to the beginning of the line.
for key in "$key_info[Escape]"{K,k}
  bindkey -M emacs "$key" backward-kill-line

# Redo.
bindkey -M emacs "$key_info[Escape]_" redo

# Search previous character.
bindkey -M emacs "$key_info[Control]X$key_info[Control]B" vi-find-prev-char

# Match bracket.
bindkey -M emacs "$key_info[Control]X$key_info[Control]]" vi-match-bracket

# Edit command in an external editor.
bindkey -M emacs "$key_info[Control]X$key_info[Control]E" edit-command-line