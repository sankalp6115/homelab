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
HOMELAB_DIR="${HOMELAB_DIR:-}"

if [[ -z "$HOMELAB_DIR" || ! -d "$HOMELAB_DIR/.git" ]]; then
    GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$GIT_ROOT" && -d "$GIT_ROOT/.git" ]]; then
        HOMELAB_DIR="$GIT_ROOT"
    elif [[ -d "$HOME/homelab/.git" ]]; then
        HOMELAB_DIR="$HOME/homelab"
    elif [[ -d "./.git" ]]; then
        HOMELAB_DIR="$(pwd)"
    fi
fi

if [[ -z "$HOMELAB_DIR" || ! -d "$HOMELAB_DIR/.git" ]]; then
    echo "Error: Homelab git repository not found."
    exit 1
fi

echo "Pulling latest updates in $HOMELAB_DIR..."
cd "$HOMELAB_DIR" && git pull
