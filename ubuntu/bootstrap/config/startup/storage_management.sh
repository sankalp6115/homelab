#!/usr/bin/env bash

TOTAL=$(df -h / | awk 'NR==2 {print $2}')
USED=$(df -h / | awk 'NR==2 {print $3}')
AVAILABLE=$(df -h / | awk 'NR==2 {print $4}')
PERCENT=$(df -h / | awk 'NR==2 {print $5}')

echo -e "Total Capacity: \033[1;34m$TOTAL\033[0m"
echo -e "Storage Used:   \033[1;31m$USED ($PERCENT)\033[0m"
echo -e "Storage Left:   \033[1;32m$AVAILABLE\033[0m"

