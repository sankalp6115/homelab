#!/usr/bin/env bash

# ─── Paths ───────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Handle being run from inside control-layer/ or from repo root
if [[ "$(basename "$SCRIPT_DIR")" == "control-layer" ]]; then
    CONTROL_DIR="$SCRIPT_DIR"
    BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    CONTROL_DIR="$SCRIPT_DIR/control-layer"
    BASE_DIR="$SCRIPT_DIR"
fi

SYSTEM_SCRIPTS="$HOME/system_scripts"
DEST_CONTROL="$SYSTEM_SCRIPTS/control-layer"

# ─── Create destination dirs ──────────────────────────────────────────────────

mkdir -p "$DEST_CONTROL"
mkdir -p "$SYSTEM_SCRIPTS/github-backup"

# Configure PATH in .bashrc and .zshrc
PATH_LINE="export PATH=\"\$HOME/system_scripts/control-layer:\$PATH\""

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]]; then
        if ! grep -qF "system_scripts/control-layer" "$rc" 2>/dev/null; then
            echo "" >> "$rc"
            echo "# homelab system scripts" >> "$rc"
            echo "$PATH_LINE" >> "$rc"
            echo "✓ Added system_scripts/control-layer to PATH in $(basename "$rc")"
        else
            echo "· PATH already set in $(basename "$rc"), skipping"
        fi
    fi
done

# ─── Copy control-layer scripts (strip .sh, make executable) ─────────────────

echo ""
echo "Installing control-layer commands → $DEST_CONTROL"

for script in "$CONTROL_DIR"/*.sh; do
    [ -f "$script" ] || continue
    base="$(basename "$script" .sh)"
    [[ "$base" == "orchestrator" ]] && continue
    if [[ "$base" == "homelab" ]]; then
        # Install as bare 'homelab' command (no prefix)
        dest="$DEST_CONTROL/homelab"
    else
        # All others get homelab- prefix
        dest="$DEST_CONTROL/homelab-$base"
    fi
    cp "$script" "$dest"
    chmod +x "$dest"
    echo "  ✓ $(basename "$dest")"
done

# ─── Remove stale unprefixed copies (from old installs) ──────────────────────

for script in "$CONTROL_DIR"/*.sh; do
    [ -f "$script" ] || continue
    base="$(basename "$script" .sh)"
    [[ "$base" == "orchestrator" ]] && continue
    stale="$DEST_CONTROL/$base"
    if [[ -f "$stale" && "$base" != "homelab" ]]; then
        rm "$stale"
        echo "  ✗ removed stale: $base"
    fi
done

# ─── Copy companion files (e.g. app-port-map.ini) ────────────────────────────

for extra in "$CONTROL_DIR"/*.ini "$CONTROL_DIR"/*.conf; do
    [ -f "$extra" ] || continue
    filename="$(basename "$extra")"
    cp "$extra" "$DEST_CONTROL/$filename"
    echo "  ✓ $filename  (config)"
done

# ─── Copy github-backup folder ────────────────────────────────────────────────

GITHUB_BACKUP_SRC="$BASE_DIR/github-backup"
if [[ -d "$GITHUB_BACKUP_SRC" ]]; then
    echo ""
    echo "Syncing github-backup → $SYSTEM_SCRIPTS/github-backup"
    cp -r "$GITHUB_BACKUP_SRC/." "$SYSTEM_SCRIPTS/github-backup/"
    chmod +x "$SYSTEM_SCRIPTS/github-backup/github-backup.py" 2>/dev/null || true
    echo "  ✓ github-backup synced"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "Done! Run: source ~/.bashrc (or source ~/.zshrc)"
echo "Then use: homelab status, homelab app-list, homelab app-up <app>, homelab battery ..."
