#!/usr/bin/env bash

# Resolve homelab directory
HOMELAB_DIR="${HOMELAB_DIR:-$HOME/homelab}"

if [[ ! -d "$HOMELAB_DIR/.git" ]]; then
    # Fallback to current directory or search
    if [[ -d "./.git" ]]; then
        HOMELAB_DIR="$(pwd)"
    fi
fi

echo "Pulling latest updates in $HOMELAB_DIR..."
cd "$HOMELAB_DIR" && git pull

