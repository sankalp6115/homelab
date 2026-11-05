#!/usr/bin/env bash
set -euo pipefail

echo "Creating standard project directories..."

mkdir -p \
  "$HOME/archives" \
  "$HOME/backups" \
  "$HOME/logs" \
  "$HOME/media" \
  "$HOME/.local/bin"

CONFIG_ROOT="${HOMELAB_CONFIG_DIR:-$HOME/.config/homelab}"
mkdir -p "$CONFIG_ROOT/startup" "$CONFIG_ROOT/scripts" "$CONFIG_ROOT/secrets"
chmod 700 "$CONFIG_ROOT/secrets"

# Backwards compatibility symlink
if [[ ! -e "$HOME/.config/termux-bootstrap" ]]; then
    ln -s "$CONFIG_ROOT" "$HOME/.config/termux-bootstrap" 2>/dev/null || true
fi

echo "Directories created successfully."
