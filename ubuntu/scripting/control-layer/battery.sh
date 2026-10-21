#!/usr/bin/env bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo ""
    echo "Usage: homelab battery"
    echo ""
    echo "Shows detailed battery information:"
    echo "  · Present, technology, health"
    echo "  · Plugged status and charging state"
    echo "  · Temperature, voltage, current draw"
    echo "  · Battery percentage"
    echo ""
    exit 0
fi

BAT_DIR=$(find /sys/class/power_supply/ -maxdepth 1 -name "BAT*" 2>/dev/null | head -n 1)

if [[ -n "$BAT_DIR" && -d "$BAT_DIR" ]]; then
    PRESENT=$(cat "$BAT_DIR/present" 2>/dev/null || echo "1")
    [[ "$PRESENT" == "1" ]] && PRESENT_STR="true" || PRESENT_STR="false"
    
    TECHNOLOGY=$(cat "$BAT_DIR/technology" 2>/dev/null || echo "Unknown")
    HEALTH=$(cat "$BAT_DIR/capacity_level" 2>/dev/null || echo "GOOD")
    STATUS=$(cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown")

    # Voltage (usually in microvolts)
    VOLTAGE_RAW=$(cat "$BAT_DIR/voltage_now" 2>/dev/null || echo "")
    if [[ -n "$VOLTAGE_RAW" ]]; then
        VOLTAGE=$(awk -v v="$VOLTAGE_RAW" 'BEGIN {printf "%.0f", v/1000}')
    else
        VOLTAGE="N/A"
    fi

    # Current (usually in microamps)
    CURRENT_RAW=$(cat "$BAT_DIR/current_now" 2>/dev/null || echo "")
    if [[ -n "$CURRENT_RAW" ]]; then
        CURRENT="$CURRENT_RAW"
    else
        CURRENT="N/A"
    fi

    # Temperature
    TEMP_RAW=$(cat "$BAT_DIR/temp" 2>/dev/null || echo "")
    if [[ -n "$TEMP_RAW" ]]; then
        TEMPERATURE=$(awk -v t="$TEMP_RAW" 'BEGIN {printf "%.1f", t/10}')
    else
        # Fallback to system thermal zone
        TEMPERATURE="N/A"
    fi

    PERCENTAGE=$(cat "$BAT_DIR/capacity" 2>/dev/null || echo "N/A")

    # Plugged status
    AC_DIR=$(find /sys/class/power_supply/ -maxdepth 1 -name "AC*" -o -name "ADP*" 2>/dev/null | head -n 1)
    if [[ -n "$AC_DIR" && -f "$AC_DIR/online" ]]; then
        AC_ONLINE=$(cat "$AC_DIR/online" 2>/dev/null || echo "0")
        [[ "$AC_ONLINE" == "1" ]] && PLUGGED="PLUGGED_AC" || PLUGGED="UNPLUGGED"
    else
        [[ "$STATUS" =~ [Cc]harging ]] && PLUGGED="PLUGGED_AC" || PLUGGED="UNPLUGGED"
    fi

    echo "Present:            $PRESENT_STR"
    echo "Technology:         $TECHNOLOGY"
    echo "Health:             $HEALTH"
    echo "Plugged:            $PLUGGED"
    echo "Status:             $STATUS"
    if [[ "$TEMPERATURE" != "N/A" ]]; then
        echo "Temperature:        ${TEMPERATURE}°C"
    else
        echo "Temperature:        N/A"
    fi
    if [[ "$VOLTAGE" != "N/A" ]]; then
        echo "Voltage:            ${VOLTAGE} mV"
    else
        echo "Voltage:            N/A"
    fi
    if [[ "$CURRENT" != "N/A" ]]; then
        echo "Current:            ${CURRENT} µA"
    else
        echo "Current:            N/A"
    fi
    echo "Battery Level:      ${PERCENTAGE}%"
else
    # Non-battery device (Desktop / Cloud VM / Homelab Server)
    echo "Present:            false"
    echo "Technology:         AC / Direct Power"
    echo "Health:             N/A"
    echo "Plugged:            PLUGGED_AC"
    echo "Status:             Continuous AC Power (Desktop / Server)"
    echo "Temperature:        N/A"
    echo "Voltage:            N/A"
    echo "Current:            N/A"
    echo "Battery Level:      N/A"
fi

