#!/usr/bin/env bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo ""
    echo "Usage: homelab wifi"
    echo ""
    echo "Shows current WiFi / Network connection details:"
    echo "  · SSID (or active interface), local IP address, default gateway"
    echo "  · Link speed (Mbps) and frequency (MHz)"
    echo ""
    exit 0
fi

# Try network-manager (nmcli) first if available
if command -v nmcli >/dev/null 2>&1; then
    WIFI_LINE=$(nmcli -t -f active,ssid,bssid,signal,freq,rate dev wifi 2>/dev/null | grep '^yes' | head -n 1 || true)
fi

GATEWAY="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"

if [[ -n "${WIFI_LINE:-}" ]]; then
    IFS=':' read -r _ SSID _ SIGNAL FREQUENCY LINK_SPEED <<< "$WIFI_LINE"
    WIFI_IFACE=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(wl|wlan)' | head -n 1)
    IP_ADDR=$(ip -4 addr show "$WIFI_IFACE" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -n 1)

    echo "SSID:        $SSID"
    echo "Gateway:     ${GATEWAY:-N/A}"
    echo "IP Address:  ${IP_ADDR:-N/A}"
    echo "Link Speed:  ${LINK_SPEED:-N/A}"
    echo "Frequency:   ${FREQUENCY:-N/A}"
else
    # Fallback: check iwconfig or iw or ethernet
    WIFI_IFACE=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(wl|wlan)' | head -n 1)
    
    if [[ -n "$WIFI_IFACE" ]] && command -v iwconfig >/dev/null 2>&1; then
        IW_OUT=$(iwconfig "$WIFI_IFACE" 2>/dev/null || true)
        SSID=$(echo "$IW_OUT" | grep -oP 'ESSID:"\K[^"]+' || echo "Unknown")
        FREQUENCY=$(echo "$IW_OUT" | grep -oP 'Frequency:\K[0-9.]+\s*GHz' || echo "N/A")
        LINK_SPEED=$(echo "$IW_OUT" | grep -oP 'Bit Rate=\K[0-9.]+\s*Mb/s' || echo "N/A")
        IP_ADDR=$(ip -4 addr show "$WIFI_IFACE" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -n 1)

        echo "SSID:        $SSID"
        echo "Gateway:     ${GATEWAY:-N/A}"
        echo "IP Address:  ${IP_ADDR:-N/A}"
        echo "Link Speed:  $LINK_SPEED"
        echo "Frequency:   $FREQUENCY"
    else
        # Machine is likely on Ethernet
        ETH_IFACE=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(eth|en)' | head -n 1)
        if [[ -n "$ETH_IFACE" ]]; then
            ETH_IP=$(ip -4 addr show "$ETH_IFACE" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -n 1)
            ETH_SPEED="1000 Mb/s"
            if command -v ethtool >/dev/null 2>&1; then
                DETECTED_SPEED=$(ethtool "$ETH_IFACE" 2>/dev/null | grep -oP 'Speed: \K.*' || true)
                [[ -n "$DETECTED_SPEED" ]] && ETH_SPEED="$DETECTED_SPEED"
            fi
            echo "Interface:   $ETH_IFACE (Ethernet)"
            echo "Gateway:     ${GATEWAY:-N/A}"
            echo "IP Address:  ${ETH_IP:-N/A}"
            echo "Link Speed:  $ETH_SPEED"
            echo "Frequency:   N/A (Wired)"
        else
            echo "SSID:        Disconnected / No Network"
            echo "Gateway:     ${GATEWAY:-N/A}"
            echo "IP Address:  N/A"
            echo "Link Speed:  N/A"
            echo "Frequency:   N/A"
        fi
    fi
fi

