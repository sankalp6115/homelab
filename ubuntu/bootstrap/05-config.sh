#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$HOME/.config/ubuntu-bootstrap"

echo "Setting up configurations..."

mkdir -p "$CONFIG_ROOT/scripts" "$CONFIG_ROOT/startup" "$CONFIG_ROOT/secrets"

cp -f "$SCRIPT_DIR/config/.zshrc" "$HOME/.zshrc" 2>/dev/null || echo "Warning: .zshrc not found"
cp -f "$SCRIPT_DIR/config/.bashrc" "$HOME/.bashrc" 2>/dev/null || echo "Warning: .bashrc not found"
cp -f "$SCRIPT_DIR/config/.tmux.conf" "$HOME/.tmux.conf" 2>/dev/null || echo "Warning: .tmux.conf not found"
cp -f "$SCRIPT_DIR/config/.nanorc" "$HOME/.nanorc" 2>/dev/null || echo "Warning: .nanorc not found"
cp -f "$SCRIPT_DIR/config/.aliases" "$HOME/.aliases" 2>/dev/null || echo "Warning: .aliases not found"

cp -f "$SCRIPT_DIR/config/ssh_login.sh" "$CONFIG_ROOT/scripts/ssh_login.sh" 2>/dev/null || echo "Warning: ssh_login.sh not found"
cp -f "$SCRIPT_DIR/config/motd.sh" "$CONFIG_ROOT/scripts/motd.sh" 2>/dev/null || echo "Warning: motd.sh not found"
chmod +x "$CONFIG_ROOT/scripts/"*.sh 2>/dev/null || true

cp -f "$SCRIPT_DIR/config/startup/ascii_art.txt" "$CONFIG_ROOT/startup/ascii_art.txt" 2>/dev/null || echo "Warning: ascii_art not found"
cp -f "$SCRIPT_DIR/config/startup/battery.sh" "$CONFIG_ROOT/startup/battery.sh" 2>/dev/null || echo "Warning: battery.sh not found"
cp -f "$SCRIPT_DIR/config/startup/interface.sh" "$CONFIG_ROOT/startup/interface.sh" 2>/dev/null || echo "Warning: interface.sh not found"
cp -f "$SCRIPT_DIR/config/startup/storage_management.sh" "$CONFIG_ROOT/startup/storage_management.sh" 2>/dev/null || echo "Warning: storage_management.sh not found"
cp -f "$SCRIPT_DIR/config/startup/weather.sh" "$CONFIG_ROOT/startup/weather.sh" 2>/dev/null || echo "Warning: weather.sh not found"
chmod +x "$CONFIG_ROOT/startup/"*.sh 2>/dev/null || true

# SSH server configuration
if command -v sudo >/dev/null 2>&1; then
    echo "Installing SSH server configuration..."
    if [[ -d "/etc/ssh/sshd_config.d" ]]; then
        sudo cp -f "$SCRIPT_DIR/config/sshd_config" "/etc/ssh/sshd_config.d/99-homelab.conf" 2>/dev/null || echo "Warning: failed to copy sshd_config into /etc/ssh/sshd_config.d/"
    else
        sudo cp -f "$SCRIPT_DIR/config/sshd_config" "/etc/ssh/sshd_config" 2>/dev/null || echo "Warning: failed to update /etc/ssh/sshd_config"
    fi
fi

# Changing shell to zsh
if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH="$(which zsh)"
    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        echo "Changing default shell to zsh ($ZSH_PATH)..."
        chsh -s "$ZSH_PATH" "$USER" 2>/dev/null || echo "Note: Run 'chsh -s $(which zsh)' manually if password prompt is needed."
    else
        echo "Default shell is already zsh."
    fi
fi

echo "Configuration files deployed."

