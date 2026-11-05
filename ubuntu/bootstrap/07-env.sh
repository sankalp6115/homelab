#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="${HOMELAB_CONFIG_DIR:-$HOME/.config/homelab}"
mkdir -p "$CONFIG_ROOT/secrets"
touch "$CONFIG_ROOT/secrets/.env"
chmod 600 "$CONFIG_ROOT/secrets/.env"

echo "Environment secrets file initialized at $CONFIG_ROOT/secrets/.env"
