.PHONY: emacs osx vim zsh 
all: emacs osx vim zsh

emacs:
	git subtree pull --squash --prefix=emacs/.emacs.d doom-emacs master
	YES=1 make -C emacs/.emacs.d
	stow -t ~ emacs

osx:
	stow -t ~ osx 

vim:
	stow -t ~ vim

zsh: 
	git submodule update --init --recursive
	stow -t ~ zsh
