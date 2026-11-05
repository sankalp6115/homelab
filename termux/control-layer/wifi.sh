#!/usr/bin/env bash

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab wifi"
    echo ""
    echo "Shows current WiFi connection details via termux-wifi-connectioninfo:"
    echo "  · SSID, local IP address, default gateway"
    echo "  · Link speed (Mbps) and frequency (MHz)"
    echo ""
    echo "Requires: termux-api package"
    echo ""
    exit 0
fi

if ! command -v termux-wifi-connectioninfo >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "Error: termux-api and jq packages are required."
    echo "Run: pkg install termux-api jq"
    exit 1
fi

WIFI_INFO="$(termux-wifi-connectioninfo 2>/dev/null || echo "{}")"

FREQUENCY="$(echo "$WIFI_INFO" | jq -r '.frequency_mhz // "N/A"')"
IP_ADDR="$(echo "$WIFI_INFO" | jq -r '.ip // "N/A"')"
LINK_SPEED="$(echo "$WIFI_INFO" | jq -r '.link_speed_mbps // "N/A"')"
SSID="$(echo "$WIFI_INFO" | jq -r '.ssid // "Disconnected"')"

GATEWAY="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"

echo "SSID:        $SSID"
echo "Gateway:     ${GATEWAY:-N/A}"
echo "IP Address:  ${IP_ADDR:-N/A}"
if [[ "$LINK_SPEED" != "N/A" && "$LINK_SPEED" != "null" ]]; then
    echo "Link Speed:  ${LINK_SPEED} Mbps"
else
    echo "Link Speed:  N/A"
fi
if [[ "$FREQUENCY" != "N/A" && "$FREQUENCY" != "null" ]]; then
    echo "Frequency:   ${FREQUENCY} MHz"
else
    echo "Frequency:   N/A"
fi
