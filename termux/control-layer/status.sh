#!/usr/bin/env bash

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo ""
    echo "Usage: homelab status"
    echo ""
    echo "Shows a full system overview including:"
    echo "  · Hostname, uptime, CPU usage, RAM, storage, battery, temperature"
    echo "  · Status of key services (sshd, tailscaled, syncthing, tmux)"
    echo "  · Network info: Network/WiFi IP and Tailscale IP"
    echo "  · All currently open/listening TCP ports"
    echo ""
    exit 0
fi

HOSTNAME="$(hostname 2>/dev/null || echo "localhost")"

UPTIME_RAW="$(uptime -p 2>/dev/null | sed 's/up //' || uptime 2>/dev/null || echo "unknown")"

# Primary IP
NORMAL_IP=$(ip -4 addr show 2>/dev/null | awk '
/inet / && !/127\.0\.0\.1/ && !/tailscale/ && !/tun/ && !/docker/ {
    split($2, a, "/")
    print a[1]
    exit
}')

# Tailscale IP
TAILSCALE_IP=""
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
fi
if [[ -z "$TAILSCALE_IP" ]]; then
    TAILSCALE_IP=$(ip -4 addr show 2>/dev/null | awk '
    /(tailscale|tun)/ { found=1 }
    found && /inet / {
        split($2, a, "/")
        print a[1]
        exit
    }')
fi

# CPU Usage percentage
CPU_LEVEL=$(top -bn1 2>/dev/null | awk '/Cpu\(s\):/ {printf "%.0f", $2 + $4}' || true)
if [[ -z "$CPU_LEVEL" || "$CPU_LEVEL" == "0" ]]; then
    CPU_LEVEL=$(top -n 1 2>/dev/null | grep -oP "System \K\d+" || true)
fi
if [[ -z "$CPU_LEVEL" ]]; then
    CPU_LEVEL=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "?")
fi

# Open Ports used by homelab python apps
OPEN_PORTS=$(ps aux 2>/dev/null | grep -E "[p]ython.*--port" | grep -oP '\-\-port\s+\K[0-9]+' | sort -un)

# Battery Info
if command -v termux-battery-status >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    BATTERY_JSON="$(termux-battery-status 2>/dev/null || echo "{}")"
    BAT_PCT=$(echo "$BATTERY_JSON" | jq -r '.percentage // empty' 2>/dev/null || true)
    BAT_STATUS=$(echo "$BATTERY_JSON" | jq -r '.status // empty' 2>/dev/null || true)
    if [[ -n "$BAT_PCT" ]]; then
        if echo "$BAT_STATUS" | grep -qi "charging"; then
            BAT_LABEL=" (Charging)"
        else
            BAT_LABEL=""
        fi
    else
        BAT_PCT="N/A"
        BAT_LABEL=""
    fi
else
    BAT_PCT="N/A"
    BAT_LABEL=""
fi

# Storage Info
STORAGE_TARGET="/data"
[[ ! -d "$STORAGE_TARGET" ]] && STORAGE_TARGET="/"
TOTAL=$(df -h "$STORAGE_TARGET" 2>/dev/null | awk 'NR==2 {print $2}')
USED=$(df -h "$STORAGE_TARGET" 2>/dev/null  | awk 'NR==2 {print $3}')
PERCENT=$(df -h "$STORAGE_TARGET" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')

RAM_USED=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')
RAM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')

# Temperature
TEMP=""
for zone in /sys/class/thermal/thermal_zone*/temp; do
    if [[ -f "$zone" ]]; then
        RAW_TEMP=$(cat "$zone" 2>/dev/null || true)
        if [[ -n "$RAW_TEMP" && "$RAW_TEMP" -gt 0 ]]; then
            TEMP=$(awk -v t="$RAW_TEMP" 'BEGIN {printf "%.0f", t/1000}')
            break
        fi
    fi
done

# ─── Services to check ───────────────────────────────────────────────────────

SERVICES=(ssh tailscaled syncthing tmux)

# ─── Colours ─────────────────────────────────────────────────────────────────

BOLD="\033[1m"
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
DIM="\033[2m"
RESET="\033[0m"

label() {
    printf "  ${DIM}%-14s${RESET}" "$1"
}

# ─── Output ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}${HOSTNAME}${RESET}  ${DIM}up ${UPTIME_RAW}${RESET}"
echo ""

printf "$(label CPU) %s%%\n"          "${CPU_LEVEL:-?}"
printf "$(label RAM) %s / %s\n"       "${RAM_USED:-?}" "${RAM_TOTAL:-?}"
printf "$(label Storage) %s%%\n"      "${PERCENT:-?}"
if [[ "$BAT_PCT" == "N/A" ]]; then
    printf "$(label Battery) %s%s\n"   "${BAT_PCT}" "${BAT_LABEL}"
else
    printf "$(label Battery) %s%%%s\n" "${BAT_PCT}" "${BAT_LABEL}"
fi
printf "$(label Temperature) %s°C\n"  "${TEMP:-?}"

# ─── Services ────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Services${RESET}"

for svc in "${SERVICES[@]}"; do
    is_running=false
    if pgrep -x "$svc" > /dev/null 2>&1; then
        is_running=true
    elif [[ "$svc" == "ssh" ]] && pgrep -x "sshd" > /dev/null 2>&1; then
        is_running=true
    elif command -v sv >/dev/null 2>&1 && sv status "$svc" 2>/dev/null | grep -q "^run:"; then
        is_running=true
    fi

    if [ "$is_running" = true ]; then
        echo -e "  ${GREEN}✓${RESET} $svc"
    else
        echo -e "  ${RED}✗${RESET} $svc"
    fi
done

# ─── Network ─────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Network${RESET}"

printf "  $(label Tailscale) %s\n"  "${TAILSCALE_IP:-N/A}"
printf "  $(label IP Address) %s\n" "${NORMAL_IP:-N/A}"

# ─── Open Ports ──────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Active Apps${RESET}"

if [[ -z "$OPEN_PORTS" ]]; then
    echo -e "  ${DIM}No python apps running with --port${RESET}"
else
    while IFS= read -r port; do
        app=$(ps aux 2>/dev/null | grep -E "[p]ython.*--port $port" | grep -oP '[\w_-]+/main\.py' | cut -d'/' -f1 || true)
        printf "  ${GREEN}●${RESET} %-12s ${DIM}%s${RESET}\n" "${app:-unknown}" "$port"
    done <<< "$OPEN_PORTS"
fi

echo ""
