#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT_MAP="$SCRIPT_DIR/app-port-map.ini"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab app-up <app-name>"
    echo ""
    echo "Starts a homelab app by name."
    echo "  · Looks up the app's port from app-port-map.ini"
    echo "  · Checks if the app is already running (skips if so)"
    echo "  · Runs the app's start.sh script"
    echo ""
    echo "Example:"
    echo "  homelab app-up melodious"
    echo ""
    exit 0
fi

APP_NAME="${1:-}"

if [[ -z "$APP_NAME" ]]; then
    echo "Usage: homelab app-up <app-name>"
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

# Check if already running
if command -v pgrep &>/dev/null; then
    pids="$(pgrep -f "main.py --port $PORT" 2>/dev/null || true)"
else
    pids="$(ps aux | grep "main.py --port $PORT" | grep -v grep | awk '{print $2}')"
fi

if [[ -n "$pids" ]]; then
    echo "$APP_NAME is already running (PIDs: $pids, port $PORT)."
    exit 0
fi

# Find start script
HOMELAB_DIR="${HOMELAB_DIR:-$HOME/homelab}"
START_SCRIPT=""
if [[ -f "$HOMELAB_DIR/apps/$APP_NAME/start.sh" ]]; then
    START_SCRIPT="$HOMELAB_DIR/apps/$APP_NAME/start.sh"
elif [[ -f "$HOMELAB_DIR/$APP_NAME/start.sh" ]]; then
    START_SCRIPT="$HOMELAB_DIR/$APP_NAME/start.sh"
fi

if [[ -z "$START_SCRIPT" ]]; then
    echo "No start.sh found for $APP_NAME (searched $HOMELAB_DIR/apps/$APP_NAME/start.sh)"
    exit 1
fi

echo "Starting $APP_NAME (port $PORT)..."
bash "$START_SCRIPT"
