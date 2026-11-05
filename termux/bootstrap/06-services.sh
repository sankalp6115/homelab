#!/usr/bin/env bash
set -euo pipefail

echo "Enabling and starting Termux services..."

if [[ -f "${PREFIX:-}/etc/profile.d/start-services.sh" ]]; then
    source "$PREFIX/etc/profile.d/start-services.sh" 2>/dev/null || true
fi

export SVDIR="${PREFIX:-}/var/service"
sleep 1

if command -v sv-enable >/dev/null 2>&1; then
    sv-enable sshd 2>/dev/null || echo "Warning: Failed to enable sshd via termux-services"
    sv up sshd 2>/dev/null || echo "Warning: Failed to start sshd via termux-services"
elif command -v sshd >/dev/null 2>&1; then
    sshd 2>/dev/null || true
fi

sleep 1
if pgrep -x "sshd" >/dev/null 2>&1; then
    echo "SSH ✓"
else
    echo "SSH ✗"
fi

echo "Services health check complete."
