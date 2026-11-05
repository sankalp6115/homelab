#!/usr/bin/env bash

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab ports"
    echo ""
    echo "Lists ports currently in use by Python processes:"
    echo "  · Looks for '--port <N>' in process command lines"
    echo "  · Resolves the app name from the script path"
    echo ""
    exit 0
fi

PORTS=$(ps aux 2>/dev/null | grep -E "[p]ython.*--port" | grep -oP '\-\-port\s+\K[0-9]+' | sort -un)

if [[ -z "$PORTS" ]]; then
    echo "No Python processes listening on any port."
else
    echo ""
    while IFS= read -r port; do
        app=$(ps aux 2>/dev/null | grep -E "[p]ython.*--port $port" | grep -oP '[\w_-]+/main\.py' | cut -d'/' -f1 || true)
        if [[ -n "$app" ]]; then
            printf "  %-8s %s\n" "$port" "$app"
        else
            printf "  %-8s %s\n" "$port" "unknown"
        fi
    done <<< "$PORTS"
    echo ""
fi
