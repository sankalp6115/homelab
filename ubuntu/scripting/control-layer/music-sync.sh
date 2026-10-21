#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab music-sync"
    echo ""
    echo "Syncs songs from an rclone remote to the melodious app, then restarts it."
    echo "  · Runs a dry-run first and shows what would change"
    echo "  · Asks for confirmation before applying"
    echo "  · Syncs homedrive:songs → ~/homelab/apps/melodious/assets/songs/"
    echo "  · Runs library_sync.py to update the music database"
    echo "  · Restarts the melodious server in a tmux session"
    echo ""
    echo "Requires: rclone, python3 / uv, tmux"
    echo ""
    exit 0
fi

# Locate melodious app directory
APP_DIR="$HOME/homelab/apps/melodious"
if [[ ! -d "$APP_DIR" && -d "$HOME/homelab/apps/apps/melodious" ]]; then
    APP_DIR="$HOME/homelab/apps/apps/melodious"
fi

SONGS_DIR="$APP_DIR/assets/songs"
SYNC_SCRIPT="$APP_DIR/backend/tools/library_sync.py"

if ! command -v rclone >/dev/null 2>&1; then
    echo "ERROR: rclone not found" >&2
    exit 1
fi

if [[ ! -d "$APP_DIR" ]]; then
    echo "ERROR: Application directory not found: $APP_DIR" >&2
    exit 1
fi

mkdir -p "$SONGS_DIR"

echo "Checking sync changes..."
echo

if ! rclone sync --dry-run homedrive:songs "$SONGS_DIR"; then
    echo
    echo "ERROR: rclone dry-run failed." >&2
    exit 1
fi

echo
read -r -p "Apply these changes? [Y/N]: " confirmation

case "${confirmation,,}" in
    y|yes)
        echo
        echo "Starting songs sync..."

        if ! rclone sync homedrive:songs "$SONGS_DIR"; then
            echo "ERROR: rclone sync failed." >&2
            exit 1
        fi

        echo "Songs synced successfully."
        ;;
    n|no)
        echo "Sync rejected."
        exit 0
        ;;
    *)
        echo "Invalid input. Sync rejected." >&2
        exit 1
        ;;
esac

# Run library sync
RUNNER="python3"
if command -v uv >/dev/null 2>&1; then
    RUNNER="uv run"
fi

if [[ -f "$SYNC_SCRIPT" ]]; then
    if ! $RUNNER "$SYNC_SCRIPT"; then
        echo "ERROR: Library sync failed." >&2
        exit 1
    fi
    echo "Library sync completed successfully."
else
    echo "Note: $SYNC_SCRIPT not found, skipping database update."
fi

# Stop existing melodious server process
if pids=$(pgrep -f 'main.py --port 3000' 2>/dev/null); then
    echo "Stopping process: $pids"
    kill $pids
    sleep 1
fi

if command -v tmux &>/dev/null && tmux has-session -t "melodious" 2>/dev/null; then
    tmux kill-session -t "melodious" 2>/dev/null || true
fi

# Start melodious in tmux session
if command -v tmux >/dev/null 2>&1; then
    tmux new-session -d -s "melodious" "cd $APP_DIR/backend && $RUNNER main.py --port 3000"
    echo "Started melodious in tmux session 'melodious'."
else
    echo "Warning: tmux not found, please start melodious manually."
fi

