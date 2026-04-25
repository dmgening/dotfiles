.PHONY: all zsh kitty nvim tmux claude-code

all: zsh nvim kitty tmux claude-code

kitty nvim tmux claude-code:
	stow -t ~ $@
ifeq ($(shell uname),Darwin)
	@[ -d macos/$@ ] && stow -d macos -t ~ $@ || true
endif

zsh:
	git submodule update --init --recursive
	stow -t ~ $@
