.PHONY: emacs osx vim zsh 
all: emacs osx vim zsh

emacs:
	make -C emacs/.emacs.d
	stow -t ~ emacs

osx:
	stow -t ~ osx 

vim:
	stow -t ~ vim

zsh: 
	git submodule update --init --recursive
	stow -t ~ zsh
