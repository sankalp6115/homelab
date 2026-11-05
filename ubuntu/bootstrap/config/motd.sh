#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="${HOMELAB_CONFIG_DIR:-$HOME/.config/homelab}"
ASCII_ART_FILE="$CONFIG_ROOT/startup/ascii_art.txt"

if [[ -f "$ASCII_ART_FILE" ]]; then
    cat "$ASCII_ART_FILE"
    echo
fi

# Run control layer commands (battery, wifi, storage)
run_control() {
    local cmd="$1"
    if command -v homelab >/dev/null 2>&1; then
        homelab "$cmd" 2>/dev/null || true
    elif [[ -x "$HOME/system_scripts/control-layer/homelab-$cmd" ]]; then
        "$HOME/system_scripts/control-layer/homelab-$cmd" 2>/dev/null || true
    elif [[ -x "$HOME/system_scripts/control-layer/homelab" ]]; then
        "$HOME/system_scripts/control-layer/homelab" "$cmd" 2>/dev/null || true
    fi
}

run_control battery
echo
run_control wifi
echo
run_control storage
echo
date
