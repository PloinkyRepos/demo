#!/bin/sh
# ============================================================================
# install.sh - Skill Explorer Container Installation Script
# ============================================================================
# This script runs inside the container during ploinky agent installation.
# It verifies the skill-manager built-in skills.
#
# NOTE: The install hook runs with /code mounted read-only.
# Directory creation is done in postinstall.sh which runs after container start.
#
# NOTE: skill-manager-skills/ directory should be included in the skill-explorer
# source directory (copied from skill-manager-cli/skill-manager/src/.AchillesSkills)
# so it's available inside the container at /code/skill-manager-skills/
# ============================================================================
set -e

cd /code

echo "============================================"
echo "Installing skill-explorer..."
echo "============================================"

# ============================================================================
# Verify skill-manager built-in skills
# ============================================================================
# The skill-manager-skills directory should already be in /code/ from the source
if [ -d "/code/skill-manager-skills" ]; then
  SKILL_COUNT=$(find /code/skill-manager-skills -maxdepth 1 -type d 2>/dev/null | wc -l)
  SKILL_COUNT=$((SKILL_COUNT - 1))
  echo "Found skill-manager-skills/ with $SKILL_COUNT built-in skills"
else
  echo "Warning: skill-manager-skills/ not found in /code/"
  echo "Built-in skills will not be available."
  echo "You can still create custom skills in .AchillesSkills/"
fi

# ============================================================================
# Verify installation
# ============================================================================
echo ""
echo "============================================"
echo "Installation complete!"
echo "============================================"
echo ""
echo "Directory structure (will be created on first run):"
echo "  /code/.AchillesSkills/     - Your custom skills"
echo "  /code/skill-manager-skills/ - Built-in skills"
echo "  /code/tools/               - MCP tool scripts"
echo ""

# Check if achillesAgentLib is available
if [ -d "/code/node_modules/achillesAgentLib" ]; then
  echo "achillesAgentLib: installed"
else
  echo "achillesAgentLib: NOT FOUND (agent may not work)"
fi

# Count available skills
BUILTIN_COUNT=$(find /code/skill-manager-skills -maxdepth 1 -type d 2>/dev/null | wc -l)
BUILTIN_COUNT=$((BUILTIN_COUNT - 1))
echo "Built-in skills: $BUILTIN_COUNT"

echo ""
echo "skill-explorer is ready!"
