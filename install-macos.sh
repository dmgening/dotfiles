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
else
    echo "Installing missing tools:"
    for tool in "${TO_INSTALL[@]}"; do
        echo "  → $tool"
    done
    echo

    brew install "${TO_INSTALL[@]}"

    echo
    echo "✓ Brew installation complete!"
fi

echo
# Install TPM (tmux plugin manager)
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing TPM (tmux plugin manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "  ✓ TPM installed"
else
    echo "  ✓ TPM already installed"
fi


# kb popup — OS-level hotkey daemon
if ! brew list skhd >/dev/null 2>&1; then
  brew tap koekeishiya/formulae
  brew install skhd
fi
skhd --start-service

# Free Cmd+Alt+Space from Spotlight (Show Finder search window)
# 65 = Spotlight's "Show Finder search window" symbolic hotkey
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 \
  '<dict><key>enabled</key><false/></dict>'

cat <<'EOF'

============================================================
kb popup — manual setup steps remaining:
  1. Reboot or logout/login (Spotlight unbind takes effect)
  2. System Settings → Privacy & Security → Accessibility
     → enable skhd if not already enabled
  3. Press Cmd+Alt+Space to verify the popup launches
============================================================
EOF

echo
echo "Next steps:"
echo "  1. Run 'make zsh' to stow zsh configuration"
echo "  2. Run 'make tmux' to stow tmux configuration"
echo "  3. Open tmux and press prefix + I to install plugins"
echo "  4. Open a new terminal to see the changes"
echo "  5. Customize Starship: ~/.config/starship.toml"
echo "  6. Customize Atuin: ~/.config/atuin/config.toml"
