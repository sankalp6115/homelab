#!/usr/bin/env bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo ""
    echo "Usage: homelab storage [mount_point]"
    echo ""
    echo "Shows internal storage usage for root / partition (or specified mount):"
    echo "  · Total capacity"
    echo "  · Used space (with percentage)"
    echo "  · Available space"
    echo ""
    exit 0
fi

MOUNT_POINT="${1:-/}"

TOTAL=$(df -h "$MOUNT_POINT" 2>/dev/null | awk 'NR==2 {print $2}')
USED=$(df -h "$MOUNT_POINT" 2>/dev/null | awk 'NR==2 {print $3}')
AVAILABLE=$(df -h "$MOUNT_POINT" 2>/dev/null | awk 'NR==2 {print $4}')
PERCENT=$(df -h "$MOUNT_POINT" 2>/dev/null | awk 'NR==2 {print $5}')

echo -e "Total Capacity: \033[1;34m$TOTAL\033[0m"
echo -e "Storage Used:   \033[1;31m$USED ($PERCENT)\033[0m"
echo -e "Storage Left:   \033[1;32m$AVAILABLE\033[0m"

