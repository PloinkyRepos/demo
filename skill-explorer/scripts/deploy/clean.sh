#!/bin/sh
# ============================================================================
# clean.sh - Clean up skill-explorer test workspace
# ============================================================================
# This script removes all ploinky state and containers.
# Use this to start fresh.
#
# Usage: ./clean.sh
# ============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$WORKSPACE_DIR"

echo "============================================"
echo "Cleaning skill-explorer test workspace"
echo "============================================"

# Stop and destroy ploinky
echo "Stopping ploinky..."
ploinky destroy 2>/dev/null || true

# Stop containers (try podman first, then docker)
if command -v podman >/dev/null 2>&1; then
    echo "Stopping podman containers..."
    podman stop -a 2>/dev/null || true
    podman rm -f -a 2>/dev/null || true
elif command -v docker >/dev/null 2>&1; then
    echo "Stopping docker containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm -f $(docker ps -aq) 2>/dev/null || true
fi

# Remove workspace directories
echo "Removing workspace directories..."
rm -rf "$WORKSPACE_DIR/.ploinky"
rm -rf "$WORKSPACE_DIR/skill-explorer"
rm -rf "$WORKSPACE_DIR/shared"

echo ""
echo "============================================"
echo "Cleanup complete!"
echo "============================================"
echo ""
echo "To start fresh, run:"
echo "  ./scripts/deploy/deploy-dev.sh"
