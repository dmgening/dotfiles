# CLAUDE.md

## Project overview

Personal dotfiles repo for macOS. Configs are organized as GNU Stow packages and symlinked to `~` via `make <target>`.

## Structure

- Each top-level directory (`zsh/`, `nvim/`, `kitty/`, `tmux/`, `git/`) is a Stow package mirroring `$HOME`
- Configs follow XDG Base Directory spec (`~/.config/<app>/`)
- `Makefile` — stow targets for each package
- `install-macos.sh` — Homebrew-based CLI tool installer
- `.stowrc` — global stow options (ignores README, Makefile, .git*)

## Key conventions

- **Stow layout**: files inside each package directory are placed exactly where they should appear relative to `~`. Don't add files outside the expected XDG paths.
- **Zsh config.d**: numbered files in `zsh/.config/zsh/config.d/` are sourced in order. Use the numbering scheme (001-049 core, 100+ language/tool, 900+ programs).
- **Neovim plugins**: plugin specs go in `nvim/.config/nvim/lua/plugins/`. Each file returns a table for lazy.nvim. Update `lazy-lock.json` after adding plugins.
- **Secrets**: `zsh/.config/zsh/secrets.sh` is gitignored. Never commit credentials.

## Common tasks

```sh
# Stow a package
make zsh        # or nvim, kitty, tmux, git, vim

# Install CLI dependencies
./install-macos.sh

# Test zsh config loads cleanly
zsh -i -c exit

# Test nvim config
nvim --headless "+Lazy! sync" +qa
```

## Things to watch out for

- The `zsh/.zshenv` sets `ZDOTDIR` to `~/.config/zsh/runcom` — all zsh runcom files live there, not in `~`
- Git config uses `[include] path = config.local` for machine-specific settings (email, signing key). The `config.local` file is not tracked.
- Kitty has auto-switching dark/light themes via `dark-theme.auto.conf` and `light-theme.auto.conf`
