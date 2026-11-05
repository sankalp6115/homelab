#!/usr/bin/env bash
set -euo pipefail

echo "Starting system update and preparation for Termux..."
read -t 30 -p "Press [Enter] to continue or [Ctrl + C] to exit..." || true
echo

echo "Updating package repositories and upgrading system packages..."
pkg update -y && pkg upgrade -y

echo
echo "Checking storage access..."
if [ -d "$HOME/storage" ]; then
    echo "✓ Storage already configured."
else
    echo "Setting up storage access..."
    termux-setup-storage

    echo "Please grant the storage permission popup on your device."
    read -p "Press [Enter] after granting permission..." || true

    if [ -d "$HOME/storage" ]; then
        echo "✓ Storage configured successfully."
    else
        echo "Warning: Storage directory not found yet. You can run 'termux-setup-storage' manually later."
    fi
fi

echo
echo "System Information:"
uname -a
echo "Architecture: $(uname -m)"
echo "Termux Version: ${TERMUX_VERSION:-unknown}"
echo "Android Version: $(getprop ro.build.version.release 2>/dev/null || echo 'unknown')"
