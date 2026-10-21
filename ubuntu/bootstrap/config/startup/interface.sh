#!/usr/bin/env bash

# Detect WiFi IPv4
WIFI_IFACE=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(wl|wlan)' | head -n 1)
if [[ -n "$WIFI_IFACE" ]]; then
    WIFI_IP=$(ip -4 addr show "$WIFI_IFACE" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -n 1)
else
    WIFI_IP=""
fi

# Detect Ethernet IPv4 (very common on Ubuntu homelabs)
ETH_IFACE=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(eth|en)' | head -n 1)
if [[ -n "$ETH_IFACE" ]]; then
    ETH_IP=$(ip -4 addr show "$ETH_IFACE" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -n 1)
else
    ETH_IP=""
fi

# Detect Tailscale IPv4
if command -v tailscale >/dev/null 2>&1; then
    TUN_IP=$(tailscale ip -4 2>/dev/null || true)
fi
if [[ -z "${TUN_IP:-}" ]]; then
    TUN_IP=$(ip -4 addr show tailscale0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -n 1 || true)
fi
if [[ -z "${TUN_IP:-}" ]]; then
    TUN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -n 1 || true)
fi

if [[ -n "$WIFI_IP" ]]; then
    echo "WiFi IPv4:      ${WIFI_IP:-N/A}"
elif [[ -n "$ETH_IP" ]]; then
    echo "Ethernet IPv4:  ${ETH_IP:-N/A}"
else
    echo "Network IPv4:   N/A"
fi

echo "Tailscale IPv4: ${TUN_IP:-N/A}"

