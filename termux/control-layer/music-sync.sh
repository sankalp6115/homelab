#!/usr/bin/env bash

# ─── Help ─────────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab music-sync"
    echo ""
    echo "Syncs songs from rclone remote → local melodious app:"
    echo "  · Checks rclone for new/modified songs (dry run first)"
    echo "  · Prompts for confirmation before downloading"
    echo "  · Runs library_sync.py to update the music database"
    echo "  · Restarts the melodious server in a tmux session"
    echo ""
    echo "Requires: rclone, python3 / uv, tmux"
    echo ""
    exit 0
fi

# Locate melodious app directory
HOMELAB_DIR="${HOMELAB_DIR:-$HOME/homelab}"
APP_DIR="$HOMELAB_DIR/apps/melodious"
if [[ ! -d "$APP_DIR" && -d "$HOMELAB_DIR/melodious" ]]; then
    APP_DIR="$HOMELAB_DIR/melodious"
fi

SONGS_DIR="$APP_DIR/assets/songs"
SYNC_SCRIPT="$APP_DIR/backend/tools/library_sync.py"

if ! command -v rclone &>/dev/null; then
    echo "Error: rclone is not installed."
    exit 1
fi

if ! rclone listremotes 2>/dev/null | grep -q "^songs:"; then
    echo "Error: rclone remote 'songs:' is not configured."
    echo "Run: rclone config"
    exit 1
fi

mkdir -p "$SONGS_DIR"

echo "Checking sync changes..."
echo

# Dry run to see what would be copied
changes=$(rclone copy --dry-run "songs:/" "$SONGS_DIR" 2>&1 | grep "NOTICE: " || true)

if [[ -z "$changes" ]]; then
    echo "Everything is up to date. Nothing to sync."
    exit 0
fi

echo "The following files will be synced:"
echo "$changes" | sed 's/NOTICE: //'
echo

# Prompt user for confirmation
read -r -p "Do you want to proceed with the sync? [y/N]: " confirm || true
confirm="${confirm:-n}"

case "$confirm" in
    [yY][eE][sS]|[yY])
        echo "Starting sync..."
        if ! rclone copy --progress "songs:/" "$SONGS_DIR"; then
            echo "ERROR: rclone sync failed." >&2
            exit 1
        fi
        echo "Sync completed successfully."
        ;;
    *)
        echo "Sync canceled by user."
        exit 0
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
if pids=$(pgrep -f 'main.py --port 3000' 2>/dev/null || true); then
    if [[ -n "$pids" ]]; then
        echo "Stopping process: $pids"
        kill $pids 2>/dev/null || true
        sleep 1
    fi
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
