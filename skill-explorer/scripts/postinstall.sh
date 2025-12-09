#!/bin/sh
# ============================================================================
# postinstall.sh - Skill Explorer Post-Installation Script
# ============================================================================
# This script runs inside the container AFTER the agent starts.
# It creates directories in /code which requires PLOINKY_CODE_WRITABLE=1.
#
# The postinstall hook runs inside the actual container where /code is
# mounted with write permissions (when PLOINKY_CODE_WRITABLE=1).
# ============================================================================
set -e

cd /code

echo "============================================"
echo "Post-install: Creating directories..."
echo "============================================"

# Create directories that require write access to /code
mkdir -p /code/.AchillesSkills
mkdir -p /code/logs

# Make scripts executable
chmod +x /code/tools/*.sh 2>/dev/null || true
chmod +x /code/scripts/*.sh 2>/dev/null || true
chmod +x /code/scripts/deploy/*.sh 2>/dev/null || true

echo "Post-install complete!"
