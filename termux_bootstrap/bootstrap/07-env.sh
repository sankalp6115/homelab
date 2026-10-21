#!/usr/bin/env bash
set -euo pipefail

CONFIG_ROOT="$HOME/.config/termux-bootstrap"
mkdir -p "$CONFIG_ROOT/secrets"
touch "$CONFIG_ROOT/secrets/.env"