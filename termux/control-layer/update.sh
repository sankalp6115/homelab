#!/usr/bin/env bash

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab update"
    echo ""
    echo "Pulls the latest Git updates for the homelab repository."
    echo ""
    exit 0
fi

# Resolve homelab directory
HOMELAB_DIR="${HOMELAB_DIR:-$HOME/homelab}"

if [[ ! -d "$HOMELAB_DIR/.git" ]]; then
    if [[ -d "./.git" ]]; then
        HOMELAB_DIR="$(pwd)"
    fi
fi

if [[ ! -d "$HOMELAB_DIR/.git" ]]; then
    echo "Error: Homelab git repository not found at $HOMELAB_DIR"
    exit 1
fi

echo "Pulling latest updates in $HOMELAB_DIR..."
cd "$HOMELAB_DIR" && git pull
