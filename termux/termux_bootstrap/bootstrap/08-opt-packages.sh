#!/usr/bin/env bash
set -euo pipefail

echo "Installing optional homelab development packages for Termux..."

pkg update -y
pkg install -y python python-pip rclone termux-api

# Install Astral uv (fast Python package installer/runner used in homelab)
if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    echo "✓ Installed uv"
fi

echo "Optional packages installed successfully."
