.PHONY: all emacs osx vim zsh kitty
all: emacs osx vim zsh

osx vim kitty:
	stow -t ~ $@

emacs:
	$(MAKE) -C emacs/.emacs.d
	stow -t ~ $@

zsh:
	git submodule update --init --recursive
	stow -t ~ $@
