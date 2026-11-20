# CLAUDE.md

## Project overview

Personal dotfiles repo for macOS. Configs are organized as GNU Stow packages and symlinked to `~` via `make <target>`.

## Structure

- Each top-level directory (`zsh/`, `fish/`, `mise/`, `nvim/`, `kitty/`, `tmux/`, `git/`) is a Stow package mirroring `$HOME`
- Configs follow XDG Base Directory spec (`~/.config/<app>/`)
- `Makefile` — stow targets for each package
- `install-macos.sh` — Homebrew-based CLI tool installer
- `.stowrc` — global stow options (ignores README, Makefile, .git*)

## Key conventions

- **Stow layout**: files inside each package directory are placed exactly where they should appear relative to `~`. Don't add files outside the expected XDG paths.
- **Zsh config.d**: numbered files in `zsh/.config/zsh/config.d/` are sourced in order. Use the numbering scheme (001-049 core, 100+ language/tool, 900+ programs).
- **Fish conf.d**: `fish/.config/fish/conf.d/*.fish` use the same numbering; fish sources them itself in name order. Guard interactive-only setup with `status is-interactive; or return`. Functions go in `functions/<name>.fish` (autoloaded). `config.fish` is not tracked: it stays machine-local (secrets, lines tool installers append). Private packages put their snippets straight into `~/.config/fish/conf.d/`.
- **Runtimes (mise)**: node, python, go, uv, pnpm come from mise, not Homebrew or pyenv/nvm/gvm. Global versions live in `mise/.config/mise/config.toml`; `mise use -g` writes through the stow symlink, so review the diff. Work-only tools go in `~/.config/mise/conf.d/*.toml` from private packages. zsh activates mise in `config.d/100-mise.sh` (shims in `.zprofile`); fish needs nothing, Homebrew's `vendor_conf.d/mise-activate.fish` does it.
- **Neovim plugins**: plugin specs go in `nvim/.config/nvim/lua/plugins/`. Each file returns a table for lazy.nvim. Update `lazy-lock.json` after adding plugins.
- **Secrets**: `zsh/.config/zsh/secrets.sh` is gitignored. Never commit credentials.

## Common tasks

```sh
# Stow a package
make zsh        # or fish, mise, nvim, kitty, tmux, git, vim

# Install the runtimes from the global mise config
mise install

# Install CLI dependencies
./install-macos.sh

# Test zsh config loads cleanly
zsh -i -c exit

# Test fish config loads cleanly
fish -i -c exit

# Test nvim config
nvim --headless "+Lazy! sync" +qa
```

## Public repo

This repo is public on GitHub. Nothing employer-specific goes here: company names, hosts, repos, cloud projects, clusters, people, account IDs, company Claude plugins/skills/hooks. Those live in `~/Projects/dotfiles-private/<company>/` (stow packages, see its README); public configs only reference them generically (`@~/.claude/CLAUDE.work.md`, `~/.config/zsh-private/`, `intent.*` git config). The global pre-commit (`git/.config/git/hooks/pre-commit`) refuses staged lines matching the private denylists in any GitHub repo without a `.leak-guard-skip` file.

## Things to watch out for

- The `zsh/.zshenv` sets `ZDOTDIR` to `~/.config/zsh/runcom` — all zsh runcom files live there, not in `~`
- Git config uses `[include] path = config.local` for machine-specific settings (email, signing key). The `config.local` file is not tracked.
- Kitty has auto-switching dark/light themes via `dark-theme.auto.conf` and `light-theme.auto.conf`
