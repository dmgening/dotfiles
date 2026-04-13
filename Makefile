.PHONY: all osx zsh kitty nvim tmux claude-code
all: zsh nvim kitty tmux claude-code

osx kitty nvim tmux claude-code:
	stow -t ~ $@

zsh:
	git submodule update --init --recursive
	stow -t ~ $@
