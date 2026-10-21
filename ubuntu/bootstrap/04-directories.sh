#!/usr/bin/env bash
set -euo pipefail

echo "Creating standard project directories..."

mkdir -p \
  "$HOME/archives" \
  "$HOME/backups" \
  "$HOME/logs" \
  "$HOME/media" \
  "$HOME/.local/bin"

CONFIG_ROOT="$HOME/.config/ubuntu-bootstrap"
mkdir -p "$CONFIG_ROOT/startup" "$CONFIG_ROOT/scripts" "$CONFIG_ROOT/secrets"
chmod 700 "$CONFIG_ROOT/secrets"

echo "Directories created successfully."

