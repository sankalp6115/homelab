#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="${HOMELAB_CONFIG_DIR:-$HOME/.config/homelab}"
AUDIO_FILE="$CONFIG_ROOT/scripts/login.mp3"

if [ -t 0 ] && [ -z "${SSH_ORIGINAL_COMMAND:-}" ]; then
    if [ -n "${SSH_CLIENT:-}" ]; then
        read -r client_ip client_port _ <<< "$SSH_CLIENT"

        if [ -f "$AUDIO_FILE" ] && command -v termux-media-player >/dev/null 2>&1; then
            termux-media-player play "$AUDIO_FILE" >/dev/null 2>&1 || true
        fi

        if command -v termux-toast >/dev/null 2>&1; then
            termux-toast "SSH Login Detected" >/dev/null 2>&1 || true
        fi

        if command -v termux-notification >/dev/null 2>&1; then
            termux-notification \
                --title "SSH Login" \
                --content "${client_ip}:${client_port} SSHed to server" >/dev/null 2>&1 || true
        fi

        mkdir -p "$HOME/logs"

        printf '[%s] %s:%s logged in\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$client_ip" \
            "$client_port" >> "$HOME/logs/ssh_login.log"
    fi
fi
