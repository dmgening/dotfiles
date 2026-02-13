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
echo "Next steps:"
echo "  1. Run 'make zsh' to stow zsh configuration"
echo "  2. Open a new terminal to see the changes"
echo "  3. Customize Starship: ~/.config/starship.toml"
echo "  4. Customize Atuin: ~/.config/atuin/config.toml"
