.PHONY: all zsh fish mise kitty nvim tmux claude-code skhd caddy lmstudio

all: zsh fish mise nvim kitty tmux claude-code skhd

kitty nvim tmux skhd:
	stow -t ~ $@
ifeq ($(shell uname),Darwin)
	@[ -d macos/$@ ] && stow -d macos -t ~ $@ || true
endif

zsh:
	git submodule update --init --recursive
	stow -t ~ $@

# --no-folding: fish and tools like OrbStack write config.fish, fish_variables,
# completions/ and conf.d/ into ~/.config/fish; keep them out of the repo
fish:
	stow -t ~ --no-folding $@

# --no-folding: conf.d/ snippets from ~/Projects/dotfiles-private land in
# ~/.config/mise; config.toml stays a link, `mise use -g` writes through it
mise:
	stow -t ~ --no-folding $@

# --no-folding: ~/.claude/hooks and ~/.claude/skills also get links from ~/Projects/dotfiles-private
claude-code:
	stow -t ~ --no-folding $@

# Not in `all`: it starts a service on port 80. The Homebrew service reads
# $(brew --prefix)/etc/Caddyfile, so link that to the stowed config.
caddy:
	stow -t ~ --no-folding $@
	ln -sf ~/.config/caddy/Caddyfile "$$(brew --prefix)/etc/Caddyfile"
	brew services restart caddy

# Not in `all`: it keeps a model in memory from every login. --no-folding:
# ~/.local/bin and ~/Library/LaunchAgents hold files from elsewhere too.
# bootout first so launchd reads a changed plist; bootstrap also runs it now.
lmstudio:
	stow -t ~ --no-folding $@
	launchctl bootout gui/$$(id -u)/local.lms-autoload 2>/dev/null || true
	launchctl bootstrap gui/$$(id -u) ~/Library/LaunchAgents/local.lms-autoload.plist
