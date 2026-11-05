#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT_MAP="$SCRIPT_DIR/app-port-map.ini"
if [[ ! -f "$PORT_MAP" && -f "$HOME/system_scripts/control-layer/app-port-map.ini" ]]; then
    PORT_MAP="$HOME/system_scripts/control-layer/app-port-map.ini"
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab app-down <app-name>"
    echo ""
    echo "Stops a running homelab app by name."
    echo "  · Looks up the app's port from app-port-map.ini"
    echo "  · Finds the running process and kills it"
    echo "  · Cleans up any associated tmux session"
    echo ""
    echo "Example:"
    echo "  homelab app-down melodious"
    echo ""
    exit 0
fi

APP_NAME="${1:-}"

if [[ -z "$APP_NAME" ]]; then
    echo "Usage: homelab app-down <app-name>"
    exit 1
fi

if [[ ! -f "$PORT_MAP" ]]; then
    echo "Error: app-port-map.ini not found at $PORT_MAP"
    exit 1
fi

PORT="$(grep "^$APP_NAME " "$PORT_MAP" | awk '{print $2}')"

if [[ -z "$PORT" ]]; then
    echo "Unknown app: $APP_NAME (not found in app-port-map.ini)"
    exit 1
fi

echo "Stopping $APP_NAME (port $PORT)..."

if command -v pgrep &>/dev/null; then
    pids="$(pgrep -f "main.py --port $PORT" 2>/dev/null || true)"
else
    pids="$(ps aux | grep "main.py --port $PORT" | grep -v grep | awk '{print $2}')"
fi

stopped=false

if [[ -n "$pids" ]]; then
    echo "Killing PIDs: $pids"
    kill $pids 2>/dev/null || true
    sleep 1

    # Check if process is still alive and force kill if needed
    for pid in $pids; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    done
    stopped=true
fi

# Clean up tmux session if present
if command -v tmux &>/dev/null && tmux has-session -t "$APP_NAME" 2>/dev/null; then
    tmux kill-session -t "$APP_NAME" 2>/dev/null || true
    stopped=true
fi

if [[ "$stopped" = true ]]; then
    echo "$APP_NAME stopped."
else
    echo "$APP_NAME is not running."
fi
