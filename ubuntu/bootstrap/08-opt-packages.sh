#!/usr/bin/env bash
set -euo pipefail

echo "Installing optional homelab development packages..."

if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

$SUDO apt update

# Python environment
$SUDO DEBIAN_FRONTEND=noninteractive apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    rclone

# Install Astral uv (fast Python package installer/runner used in homelab)
if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    echo "✓ Installed uv"
fi

echo "Optional packages installed successfully."

