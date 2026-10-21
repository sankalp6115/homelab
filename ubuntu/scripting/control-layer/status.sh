#!/usr/bin/env bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo ""
    echo "Usage: homelab status"
    echo ""
    echo "Shows a full system overview including:"
    echo "  · Hostname, uptime, CPU usage, RAM, storage, battery, temperature"
    echo "  · Status of key services (ssh, tailscaled, syncthing, tmux)"
    echo "  · Network info: Network/WiFi IP and Tailscale IP"
    echo "  · All currently open/listening TCP ports"
    echo ""
    exit 0
fi

HOSTNAME="$(hostname)"

UPTIME_RAW="$(uptime -p 2>/dev/null | sed 's/up //' || uptime)"

# Primary IP (WiFi or Ethernet)
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
CPU_LEVEL=$(top -bn1 2>/dev/null | awk '/Cpu\(s\):/ {printf "%.0f", $2 + $4}' || echo "?")
if [[ -z "$CPU_LEVEL" || "$CPU_LEVEL" == "?" ]]; then
    CPU_LEVEL=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "?")
fi

# Open Ports used by homelab python apps
OPEN_PORTS=$(ps aux 2>/dev/null | grep -E "[p]ython.*--port" | grep -oP '\-\-port\s+\K[0-9]+' | sort -un)

# Battery Info
BAT_DIR=$(find /sys/class/power_supply/ -maxdepth 1 -name "BAT*" 2>/dev/null | head -n 1)
if [[ -n "$BAT_DIR" && -f "$BAT_DIR/capacity" ]]; then
    BAT_PCT=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo "?")
    BAT_STATUS=$(cat "$BAT_DIR/status" 2>/dev/null || echo "")
    if echo "$BAT_STATUS" | grep -qi "charging"; then
        BAT_LABEL=" (Charging)"
    else
        BAT_LABEL=""
    fi
elif command -v upower >/dev/null 2>&1; then
    BAT_PATH=$(upower -e 2>/dev/null | grep -i battery | head -n 1)
    if [[ -n "$BAT_PATH" ]]; then
        BAT_PCT=$(upower -i "$BAT_PATH" 2>/dev/null | awk '/percentage:/ {gsub(/%/,""); print $2}')
        BAT_STATE=$(upower -i "$BAT_PATH" 2>/dev/null | awk '/state:/ {print $2}')
        if [[ "$BAT_STATE" == "charging" ]]; then
            BAT_LABEL=" (Charging)"
        else
            BAT_LABEL=""
        fi
    else
        BAT_PCT="N/A"
        BAT_LABEL=" (AC Power)"
    fi
else
    BAT_PCT="N/A"
    BAT_LABEL=" (AC Power)"
fi

TOTAL=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}')
USED=$(df -h / 2>/dev/null  | awk 'NR==2 {print $3}')
PERCENT=$(df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')

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
if [[ -z "$TEMP" ]] && command -v sensors >/dev/null 2>&1; then
    TEMP=$(sensors 2>/dev/null | awk '/Package id 0:|Core 0:|temp1:/ {gsub(/[^0-9.]/,"",$0); printf "%.0f", $0; exit}')
fi

# ─── Services to check ───────────────────────────────────────────────────────

SERVICES=(ssh tailscaled syncthing tmux)

# ─── Colours ─────────────────────────────────────────────────────────────────

BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
RESET="\033[0m"

label() { printf "${DIM}%-14s${RESET}" "$1:"; }

# ─── Header ──────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}\$ homelab-status${RESET}"
echo ""

# ─── System Info ─────────────────────────────────────────────────────────────

printf "$(label Hostname) %s\n"       "${HOSTNAME:-localhost}"
printf "$(label Uptime) %s\n"         "${UPTIME_RAW:-unknown}"
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
    elif command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$svc" 2>/dev/null; then
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
echo -e "${BOLD}Ports${RESET}"

if [ -z "$OPEN_PORTS" ]; then
    echo "  (none)"
else
    while IFS= read -r port; do
        echo "  $port"
    done <<< "$OPEN_PORTS"
fi

echo ""

