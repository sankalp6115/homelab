#!/usr/bin/env bash

# Check for Linux battery via sysfs
BAT_DIR=$(find /sys/class/power_supply/ -maxdepth 1 -name "BAT*" 2>/dev/null | head -n 1)

if [[ -n "$BAT_DIR" && -f "$BAT_DIR/capacity" ]]; then
    PCT=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo "?")
    STATUS=$(cat "$BAT_DIR/status" 2>/dev/null || echo "")
    if [[ -n "$STATUS" ]]; then
        echo "Battery: ${PCT}% (${STATUS})"
    else
        echo "Battery: ${PCT}%"
    fi
elif command -v upower >/dev/null 2>&1; then
    BAT_PATH=$(upower -e 2>/dev/null | grep -i battery | head -n 1)
    if [[ -n "$BAT_PATH" ]]; then
        PCT=$(upower -i "$BAT_PATH" 2>/dev/null | awk '/percentage:/ {print $2}')
        STATE=$(upower -i "$BAT_PATH" 2>/dev/null | awk '/state:/ {print $2}')
        echo "Battery: ${PCT} (${STATE})"
    else
        echo "Battery: N/A (AC Power / Server)"
    fi
elif command -v acpi >/dev/null 2>&1; then
    ACPI_OUT=$(acpi -b 2>/dev/null | head -n 1)
    if [[ -n "$ACPI_OUT" ]]; then
        echo "Battery: $(echo "$ACPI_OUT" | awk -F', ' '{print $2}')"
    else
        echo "Battery: N/A (AC Power / Server)"
    fi
else
    echo "Battery: N/A (AC Power / Server)"
fi

