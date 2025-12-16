#!/bin/sh
# ============================================================================
# clean.sh - Clean up skill-explorer test workspace
# ============================================================================
# This script removes ploinky state and containers for THIS workspace only.
# It uses 'ploinky destroy' to avoid affecting containers from other projects.
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

# Stop and destroy ploinky containers for this workspace only
# Using 'ploinky destroy' to avoid affecting containers from other projects
echo "Destroying ploinky workspace..."
ploinky destroy 2>/dev/null || true

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
