#!/usr/bin/env bash
set -e

echo "=== SSH Configuration ==="
echo "Configuring SSH authentication for user: $USER"

read -p "Would you like to change/set your user password for SSH login? [y/N]: " change_pass
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

