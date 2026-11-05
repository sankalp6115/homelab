#!/usr/bin/env bash

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab battery"
    echo ""
    echo "Shows detailed battery information from termux-battery-status:"
    echo "  · Present, technology, health"
    echo "  · Plugged status and charging state"
    echo "  · Temperature, voltage, current draw"
    echo "  · Battery percentage"
    echo ""
    echo "Requires: termux-api package"
    echo ""
    exit 0
fi

if ! command -v termux-battery-status >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "Error: termux-api and jq packages are required."
    echo "Run: pkg install termux-api jq"
    exit 1
fi

BATTERY_INFO="$(termux-battery-status 2>/dev/null || echo "{}")"

PRESENT="$(echo "$BATTERY_INFO" | jq -r '.present // "unknown"')"
TECHNOLOGY="$(echo "$BATTERY_INFO" | jq -r '.technology // "unknown"')"
HEALTH="$(echo "$BATTERY_INFO" | jq -r '.health // "unknown"')"
PLUGGED="$(echo "$BATTERY_INFO" | jq -r '.plugged // "unknown"')"
STATUS="$(echo "$BATTERY_INFO" | jq -r '.status // "unknown"')"
TEMPERATURE="$(echo "$BATTERY_INFO" | jq -r '.temperature // "N/A"')"
VOLTAGE="$(echo "$BATTERY_INFO" | jq -r '.voltage // "N/A"')"
CURRENT="$(echo "$BATTERY_INFO" | jq -r '.current // "N/A"')"
PERCENTAGE="$(echo "$BATTERY_INFO" | jq -r '.percentage // "N/A"')"

echo "Present:            $PRESENT"
echo "Technology:         $TECHNOLOGY"
echo "Health:             $HEALTH"
echo "Plugged:            $PLUGGED"
echo "Status:             $STATUS"
if [[ "$TEMPERATURE" != "N/A" && "$TEMPERATURE" != "null" ]]; then
    echo "Temperature:        ${TEMPERATURE}°C"
else
    echo "Temperature:        N/A"
fi
if [[ "$VOLTAGE" != "N/A" && "$VOLTAGE" != "null" ]]; then
    echo "Voltage:            ${VOLTAGE} mV"
else
    echo "Voltage:            N/A"
fi
if [[ "$CURRENT" != "N/A" && "$CURRENT" != "null" ]]; then
    echo "Current:            ${CURRENT} µA"
else
    echo "Current:            N/A"
fi
if [[ "$PERCENTAGE" != "N/A" && "$PERCENTAGE" != "null" ]]; then
    echo "Battery Level:      ${PERCENTAGE}%"
else
    echo "Battery Level:      N/A"
fi
