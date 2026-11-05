#!/usr/bin/env bash
# =============================================================================
# init-network.sh — Create the shared 'homelab' Docker bridge network
#
# Run this ONCE before bringing up any compose stack.
# It is idempotent: re-running it is safe even if the network already exists.
#
# Usage:
#   chmod +x scripts/init-network.sh
#   ./scripts/init-network.sh
# =============================================================================

set -euo pipefail

NETWORK_NAME="homelab"
NETWORK_DRIVER="bridge"

echo "[homelab] Checking for Docker network '${NETWORK_NAME}'..."

if docker network inspect "${NETWORK_NAME}" > /dev/null 2>&1; then
  echo "[homelab] Network '${NETWORK_NAME}' already exists — nothing to do."
else
  echo "[homelab] Creating network '${NETWORK_NAME}' (driver: ${NETWORK_DRIVER})..."
  docker network create \
    --driver "${NETWORK_DRIVER}" \
    "${NETWORK_NAME}"
  echo "[homelab] Network '${NETWORK_NAME}' created successfully."
fi

echo "[homelab] Done."

