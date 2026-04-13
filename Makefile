.PHONY: all emacs osx vim zsh kitty nvim tx
all: emacs osx vim zsh tmux

osx vim kitty nvim tmux:
	stow -t ~ $@

emacs:
	$(MAKE) -C emacs/.emacs.d
	stow -t ~ $@

zsh:
	git submodule update --init --recursive
	stow -t ~ $@
