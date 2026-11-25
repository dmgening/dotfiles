# Dotfiles

Personal development environment configs managed with [GNU Stow](https://www.gnu.org/software/stow/).

Resurrected by courtesy of [Claude Code](https://claude.ai/code) and vibe-coding, since I don't have any time to maintain my own config properly.

## What's included

| Module | Description |
|--------|-------------|
| `zsh`  | Zsh config with [zinit](https://github.com/zdharma-continuum/zinit), starship prompt, atuin history, fzf, completions |
| `fish` | Minimal fish: PATH, dependency-free one-line prompt, fzf widgets and shift-tab completion with bat/eza previews, eza/bat aliases, `ask` for quick answers from a local model |
| `mise` | Global runtime versions via [mise](https://mise.jdx.dev): node LTS, python, go, uv, pnpm |
| `nvim` | Neovim 0.11+ with lazy.nvim, native LSP, treesitter, fzf-lua, oil, catppuccin |
| `tmux` | tmux 3.x+ with vim-style navigation, session persistence (resurrect + continuum) |
| `kitty`| Kitty terminal with catppuccin themes, splits, Nerd Font |
| `git`  | Git aliases, conditional includes for work profiles |
| `caddy`| Local [Caddy](https://caddyserver.com) reverse proxy: `syncthing.localhost` and other `*.localhost` names to local services |
| `lmstudio` | A login agent that starts [LM Studio](https://lmstudio.ai)'s server on `localhost:1234` and loads the small model fish's `ask` uses |

## Requirements

- GNU Stow (`brew install stow` on macOS, `apt install stow` on Debian/Ubuntu)
- macOS, Linux, or WSL

## Setup

```sh
# Install CLI tools (starship, atuin, eza, bat, ripgrep, fd, fzf, tmux)
./install-macos.sh

# Symlink configs to ~
make zsh
make fish
make mise && mise install
make nvim
make kitty
make tmux
make git
make caddy   # links the Caddyfile and (re)starts the Homebrew service
make lmstudio   # loads LM Studio's model for `ask` now and at every login
```

Each `make` target runs `stow -t ~` on the corresponding directory, creating symlinks under `~/.config/`.

## Structure

Configs follow the [XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory) spec. Each top-level directory mirrors the home directory layout so that Stow can symlink it directly:

```
zsh/.config/zsh/          -> ~/.config/zsh/
mise/.config/mise/        -> ~/.config/mise/
nvim/.config/nvim/        -> ~/.config/nvim/
kitty/.config/kitty/      -> ~/.config/kitty/
tmux/.config/tmux/        -> ~/.config/tmux/
git/.config/git/          -> ~/.config/git/
```

## Zsh plugins

Plugins are managed by zinit (auto-installed on first shell start). Configuration is split into numbered files under `zsh/.config/zsh/config.d/` loaded in order.

## Neovim plugins

Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim) (auto-bootstrapped). Plugin specs live in `nvim/.config/nvim/lua/plugins/`. Lock file is tracked for reproducible installs.
