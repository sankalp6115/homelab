#!/usr/bin/env bash
set -euo pipefail

if [ -t 0 ] && [ -z "${SSH_ORIGINAL_COMMAND:-}" ]; then
    if [ -n "${SSH_CLIENT:-}" ]; then
        read -r client_ip client_port _ <<< "$SSH_CLIENT"

        # Desktop notification if desktop environment / DBUS session is available
        if command -v notify-send >/dev/null 2>&1; then
            if [[ -n "${DISPLAY:-}" || -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
                notify-send "SSH Login" "${client_ip}:${client_port} SSHed to server" >/dev/null 2>&1 || true
            fi
        fi

        # Append to ssh_login.log
        mkdir -p "$HOME/logs"
        printf '[%s] %s:%s logged in\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$client_ip" \
            "$client_port" >> "$HOME/logs/ssh_login.log"
    fi
fi

