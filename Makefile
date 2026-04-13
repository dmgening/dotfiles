.PHONY: all osx zsh kitty nvim tmux
all: zsh nvim kitty tmux

osx kitty nvim tmux:
	stow -t ~ $@

zsh:
	git submodule update --init --recursive
	stow -t ~ $@
