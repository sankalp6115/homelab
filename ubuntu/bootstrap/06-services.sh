#!/usr/bin/env bash
set -e

echo "Enabling and starting Ubuntu services..."

if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

# Enable and start SSH service
SSH_SVC="ssh"
if systemctl list-unit-files | grep -q "^sshd.service"; then
    SSH_SVC="sshd"
fi

$SUDO systemctl enable "$SSH_SVC" 2>/dev/null || echo "Warning: Failed to enable $SSH_SVC service"
$SUDO systemctl restart "$SSH_SVC" 2>/dev/null || echo "Warning: Failed to restart $SSH_SVC service"

# Enable cron
$SUDO systemctl enable cron 2>/dev/null || true
$SUDO systemctl start cron 2>/dev/null || true

# Health check
sleep 1
if systemctl is-active --quiet "$SSH_SVC" || pgrep -x "sshd" >/dev/null 2>&1; then
    echo "SSH ✓"
else
    echo "SSH ✗"
fi

echo "Services health check complete."

