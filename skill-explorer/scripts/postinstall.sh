#!/bin/sh
# ============================================================================
# postinstall.sh - Skill Explorer Post-Installation Script
# ============================================================================
# This script runs inside the container AFTER the agent starts.
# It creates directories in /code which requires PLOINKY_CODE_WRITABLE=1.
# ============================================================================

cd /code

echo "============================================"
echo "Post-install: Creating directories..."
echo "============================================"

# Debug: check if /code is writable
echo "Checking /code permissions..."
ls -la /code/ | head -5

# Create directories that require write access to /code
echo "Creating .AchillesSkills..."
mkdir -p /code/.AchillesSkills || echo "Failed to create .AchillesSkills"

echo "Creating logs..."
mkdir -p /code/logs || echo "Failed to create logs"

echo "Post-install complete!"
