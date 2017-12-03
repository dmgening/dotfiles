Yet Another Dotfiles Repo
========
Hello stranger! Feel free to browse, fork or criticize any part of my work :)

## Fetching upstreams
[hlissner/doom-emac](https://github.com/hlissner/doom-emacs) via git subtree pull
``` sh
	git subtree pull --squash --prefix=emacs/.emacs.d doom-emacs master
```

[sorin-ionescu/prezto](https://github.com/sorin-ionescu/prezto) via git submodule
``` sh
	git submodule update --init --recursive

```

## Installation
**manual**
Symlink or copy required file to your homedir, pretty much it. See upstream
repos for extended installation instructions

**via GNU Stow**
``` sh
    # stow -t ~ <package>
    stow -t ~ zsh
```

**via Makefile**
``` sh
    make
```
Actually just calls GNU Stow for each target, but will try fetch upstreams before and call post
installation hooks if required.

## Contents

**git**
Introduces some aliases and better defaults. See `git/.gitconfig` for more details

**Emacs 25.x**
Beutifull [hlissner/doom-emac](https://github.com/hlissner/doom-emacs) with some personal flavor.
Upstream implemented via git subtree.

**Zsh**
Pretty much basic config with custom PS1, uses
[sorin-ionescu/prezto](https://github.com/sorin-ionescu/prezto). 
Availiable via git submodule.

**OS X**
Configuration for [koekeishiya/chunkwm](https://github.com/koekeishiya/chunkwm)
and associated [koekeishiya/khd](https://github.com/koekeishiya/khd). Also small
[Übersicht](http://tracesof.net/uebersicht/) widget taken from [herrbischoff/nerdbar.widget](https://github.com/herrbischoff/nerdbar.widget)

**VIM**
Tribute to traditions. Package manager, some basic confgis and aliases.
