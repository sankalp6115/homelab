#!/usr/bin/env bash

# ─── Paths ───────────────────────────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

for script in "$REPO_DIR/control-layer/"*.sh; do
    [ -f "$script" ] || continue
    base="$(basename "$script" .sh)"
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

for script in "$REPO_DIR/control-layer/"*.sh; do
    [ -f "$script" ] || continue
    base="$(basename "$script" .sh)"
    stale="$DEST_CONTROL/$base"
    if [[ -f "$stale" && "$base" != "homelab" ]]; then
        rm "$stale"
        echo "  ✗ removed stale: $base"
    fi
done

# ─── Copy companion files (e.g. app-port-map.ini) ────────────────────────────

for extra in "$REPO_DIR/control-layer/"*.ini "$REPO_DIR/control-layer/"*.conf; do
    [ -f "$extra" ] || continue
    filename="$(basename "$extra")"
    cp "$extra" "$DEST_CONTROL/$filename"
    echo "  ✓ $filename  (config)"
done

# ─── Copy github-backup folder ────────────────────────────────────────────────

echo ""
echo "Syncing github-backup → $SYSTEM_SCRIPTS/github-backup"
cp -r "$REPO_DIR/github-backup/." "$SYSTEM_SCRIPTS/github-backup/"
chmod +x "$SYSTEM_SCRIPTS/github-backup/github-backup.py" 2>/dev/null || true
echo "  ✓ github-backup synced"

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "Done! Run: source ~/.bashrc (or source ~/.zshrc)"
echo "Then use: homelab status, homelab app-list, homelab app-up <app>, homelab battery ..."

