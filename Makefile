.PHONY: all zsh mise kitty nvim tmux claude-code skhd

all: zsh mise nvim kitty tmux claude-code skhd

kitty nvim tmux skhd:
	stow -t ~ $@
ifeq ($(shell uname),Darwin)
	@[ -d macos/$@ ] && stow -d macos -t ~ $@ || true
endif

zsh:
	git submodule update --init --recursive
	stow -t ~ $@

# --no-folding: conf.d/ snippets from ~/Projects/dotfiles-private land in
# ~/.config/mise; config.toml stays a link, `mise use -g` writes through it
mise:
	stow -t ~ --no-folding $@

# --no-folding: ~/.claude/hooks and ~/.claude/skills also get links from ~/Projects/dotfiles-private
claude-code:
	stow -t ~ --no-folding $@
