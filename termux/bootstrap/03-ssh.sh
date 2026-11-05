#!/usr/bin/env bash
set -euo pipefail

echo "=== SSH Configuration ==="
USER_NAME="$(whoami 2>/dev/null || echo "${USER:-termux}")"
echo "Configuring SSH authentication for user: $USER_NAME"

read -p "Would you like to change/set your user password for SSH login? [y/N]: " change_pass || true
change_pass="${change_pass:-n}"
if [[ "${change_pass,,}" == "y" || "${change_pass,,}" == "yes" ]]; then
    passwd
else
    echo "Keeping existing user password."
fi

# Ensure ~/.ssh exists with correct permissions
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

echo "SSH user environment prepared."
