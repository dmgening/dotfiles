#!/usr/bin/env bash
set -euo pipefail

echo "Installing modern CLI tools for zsh dotfiles..."
echo

if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew not found. Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

TOOLS=(
    "starship"
    "atuin"
    "eza"
    "bat"
    "ripgrep"
    "fd"
    "fzf"
    "tmux"
)

echo "The following tools will be installed:"
for tool in "${TOOLS[@]}"; do
    echo "  - $tool"
done
echo

echo "Checking for already installed tools..."
ALREADY_INSTALLED=()
TO_INSTALL=()

for tool in "${TOOLS[@]}"; do
    if brew list --formula "$tool" &> /dev/null; then
        ALREADY_INSTALLED+=("$tool")
    else
        TO_INSTALL+=("$tool")
    fi
done

if [ ${#ALREADY_INSTALLED[@]} -gt 0 ]; then
    echo "Already installed:"
    for tool in "${ALREADY_INSTALLED[@]}"; do
        echo "  ✓ $tool"
    done
    echo
fi

if [ ${#TO_INSTALL[@]} -eq 0 ]; then
    echo "All tools are already installed!"
    exit 0
fi

echo "Installing missing tools:"
for tool in "${TO_INSTALL[@]}"; do
    echo "  → $tool"
done
echo

brew install "${TO_INSTALL[@]}"

echo
echo "✓ Installation complete!"
echo
# Install TPM (tmux plugin manager)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing TPM (tmux plugin manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "  ✓ TPM installed"
else
    echo "  ✓ TPM already installed"
fi

echo
echo "Next steps:"
echo "  1. Run 'make zsh' to stow zsh configuration"
echo "  2. Run 'make tmux' to stow tmux configuration"
echo "  3. Open tmux and press prefix + I to install plugins"
echo "  4. Open a new terminal to see the changes"
echo "  5. Customize Starship: ~/.config/starship.toml"
echo "  6. Customize Atuin: ~/.config/atuin/config.toml"
