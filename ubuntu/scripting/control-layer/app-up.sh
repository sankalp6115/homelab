#!/usr/bin/env bash
HOME_DIR="$HOME"
HOMELAB_DIR="$HOME_DIR/homelab/apps"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT_MAP="$SCRIPT_DIR/app-port-map.ini"

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo ""
    echo "Usage: homelab app-up <app-name>"
    echo ""
    echo "Starts a homelab app by name."
    echo "  · Looks up the app's port from app-port-map.ini"
    echo "  · Checks if the app is already running (skips if so)"
    echo "  · Runs the app's start.sh script from ~/homelab/apps/<app-name>/"
    echo ""
    echo "Example:"
    echo "  homelab app-up melodious"
    echo ""
    exit 0
fi

APP_NAME="$1"

if [[ -z "$APP_NAME" ]]; then
    echo "Usage: homelab app-up <app-name>"
    exit 1
fi

# Look up port from app-port-map.ini
PORT="$(grep "^$APP_NAME " "$PORT_MAP" | awk '{print $2}')"

if [[ -z "$PORT" ]]; then
    echo "Unknown app: $APP_NAME (not found in app-port-map.ini)"
    exit 1
fi

# Check if already running
if command -v pgrep &>/dev/null; then
    pids="$(pgrep -f "main.py --port $PORT")"
else
    pids="$(ps aux | grep "main.py --port $PORT" | grep -v grep | awk '{print $2}')"
fi

if [[ -n "$pids" ]]; then
    echo "$APP_NAME is already running (PIDs: $pids)"
    exit 0
fi

# Find start script
START_SCRIPT=""
if [[ -f "$HOMELAB_DIR/$APP_NAME/start.sh" ]]; then
    START_SCRIPT="$HOMELAB_DIR/$APP_NAME/start.sh"
elif [[ -f "$HOMELAB_DIR/apps/$APP_NAME/start.sh" ]]; then
    START_SCRIPT="$HOMELAB_DIR/apps/$APP_NAME/start.sh"
fi

if [[ -z "$START_SCRIPT" ]]; then
    echo "No start.sh found for $APP_NAME at $HOMELAB_DIR/$APP_NAME/start.sh"
    exit 1
fi

echo "Starting $APP_NAME (port $PORT)..."
bash "$START_SCRIPT"

