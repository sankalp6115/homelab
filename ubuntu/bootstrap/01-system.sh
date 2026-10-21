#!/usr/bin/env bash
set -e

echo "Starting system update and preparation for Ubuntu..."
read -t 15 -p "Press [Enter] to continue or [Ctrl + C] to exit..." || true
echo

# Require sudo for system updates
if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

echo "Updating package repositories and upgrading system packages..."
$SUDO apt update && $SUDO DEBIAN_FRONTEND=noninteractive apt upgrade -y

echo
echo "System Information:"
uname -a

if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a
elif [ -f /etc/os-release ]; then
    cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION)='
fi

echo "Architecture: $(uname -m)"
echo "Storage check (root filesystem):"
df -h /

