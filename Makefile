.PHONY: all zsh kitty nvim tmux claude-code skhd

all: zsh nvim kitty tmux claude-code skhd

kitty nvim tmux skhd:
	stow -t ~ $@
ifeq ($(shell uname),Darwin)
	@[ -d macos/$@ ] && stow -d macos -t ~ $@ || true
endif

zsh:
	git submodule update --init --recursive
	stow -t ~ $@

# --no-folding: ~/.claude/hooks and ~/.claude/skills also get links from ~/Projects/dotfiles-private
claude-code:
	stow -t ~ --no-folding $@
