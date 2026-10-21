#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Ubuntu Bootstrap Process..."

# Ensure sudo access is available early
if command -v sudo &>/dev/null; then
    sudo -v
fi

SCRIPTS=(
    "01-system.sh"
    "02-packages.sh"
    "03-ssh.sh"
    "04-directories.sh"
    "05-config.sh"
    "06-services.sh"
    "07-env.sh"
    "08-opt-packages.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        chmod +x "$SCRIPT_DIR/$script"
    fi
done

run_step() {
    local script_name="$1"
    local script_path="$SCRIPT_DIR/$script_name"

    if [[ ! -f "$script_path" ]]; then
        echo "Error: missing script: $script_path" >&2
        exit 1
    fi

    echo
    echo "======= $script_name ======="
    bash "$script_path"
}

for script in "${SCRIPTS[@]}"; do
    run_step "$script"
done

echo
echo "Bootstrap process complete! Please restart your shell or log out and back in."

