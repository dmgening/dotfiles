.PHONY: all emacs osx vim zsh kitty nvim
all: emacs osx vim zsh

osx vim kitty nvim:
	stow -t ~ $@

emacs:
	$(MAKE) -C emacs/.emacs.d
	stow -t ~ $@

zsh:
	git submodule update --init --recursive
	stow -t ~ $@
