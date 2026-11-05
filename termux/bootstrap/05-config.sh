#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="${HOMELAB_CONFIG_DIR:-$HOME/.config/homelab}"

echo "Setting up configurations for Termux..."

mkdir -p "$CONFIG_ROOT/scripts" "$CONFIG_ROOT/startup" "$CONFIG_ROOT/secrets"
if [[ -n "${PREFIX:-}" ]]; then
    mkdir -p "$PREFIX/etc/ssh"
fi

cp -f "$SCRIPT_DIR/config/.zshrc" "$HOME/.zshrc" 2>/dev/null || echo "Warning: .zshrc not found"
cp -f "$SCRIPT_DIR/config/.bashrc" "$HOME/.bashrc" 2>/dev/null || echo "Warning: .bashrc not found"
cp -f "$SCRIPT_DIR/config/.tmux.conf" "$HOME/.tmux.conf" 2>/dev/null || echo "Warning: .tmux.conf not found"
cp -f "$SCRIPT_DIR/config/.nanorc" "$HOME/.nanorc" 2>/dev/null || echo "Warning: .nanorc not found"
cp -f "$SCRIPT_DIR/config/.aliases" "$HOME/.aliases" 2>/dev/null || echo "Warning: .aliases not found"

if [[ -f "$SCRIPT_DIR/assets/audio/login.mp3" ]]; then
    cp -f "$SCRIPT_DIR/assets/audio/login.mp3" "$CONFIG_ROOT/scripts/login.mp3" 2>/dev/null || true
fi
cp -f "$SCRIPT_DIR/config/ssh_login.sh" "$CONFIG_ROOT/scripts/ssh_login.sh" 2>/dev/null || echo "Warning: ssh_login.sh not found"
cp -f "$SCRIPT_DIR/config/motd.sh" "$CONFIG_ROOT/scripts/motd.sh" 2>/dev/null || echo "Warning: motd.sh not found"
chmod +x "$CONFIG_ROOT/scripts/"*.sh 2>/dev/null || true

cp -f "$SCRIPT_DIR/config/startup/ascii_art.txt" "$CONFIG_ROOT/startup/ascii_art.txt" 2>/dev/null || echo "Warning: ascii_art not found"

if [[ -n "${PREFIX:-}" ]]; then
    cp -f "$SCRIPT_DIR/config/sshd_config" "$PREFIX/etc/ssh/sshd_config" 2>/dev/null || echo "Warning: sshd_config not copied"
    cp -f "$SCRIPT_DIR/config/motd" "$PREFIX/etc/motd" 2>/dev/null || echo "Warning: motd not copied"
    cp -f "$SCRIPT_DIR/config/motd.sh" "$PREFIX/etc/motd.sh" 2>/dev/null || echo "Warning: motd.sh not copied"
    chmod +x "$PREFIX/etc/motd.sh" 2>/dev/null || true
fi

# Changing shell to zsh
if command -v zsh >/dev/null 2>&1; then
    if [[ "${SHELL:-}" != *"zsh"* ]]; then
        echo "Changing default shell to zsh..."
        chsh -s zsh 2>/dev/null || echo "Note: Run 'chsh -s zsh' manually if needed."
    else
        echo "Default shell is already zsh."
    fi
fi

echo "Configuration files deployed."
