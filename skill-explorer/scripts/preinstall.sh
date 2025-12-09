#!/bin/sh
# ============================================================================
# preinstall.sh - Copy skill-manager built-in skills (runs on HOST)
# ============================================================================
# This script runs on the host machine BEFORE the container is created.
# It copies the skill-manager built-in skills into the skill-explorer directory
# so they're available inside the container.
# ============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_EXPLORER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================"
echo "Preinstall: Copying skill-manager skills..."
echo "============================================"

# Find skill-manager-cli source relative to skill-explorer
# skill-explorer is at: coralFlow/demo/skill-explorer
# skill-manager-cli is at: coralFlow/skill-manager-cli
SKILL_MGR_SRC="$SKILL_EXPLORER_DIR/../../skill-manager-cli/skill-manager/src/.AchillesSkills"

if [ -d "$SKILL_MGR_SRC" ]; then
  echo "Found skill-manager at: $SKILL_MGR_SRC"

  # Remove old copy if exists
  rm -rf "$SKILL_EXPLORER_DIR/skill-manager-skills"

  # Copy built-in skills
  cp -r "$SKILL_MGR_SRC" "$SKILL_EXPLORER_DIR/skill-manager-skills"

  SKILL_COUNT=$(find "$SKILL_EXPLORER_DIR/skill-manager-skills" -maxdepth 1 -type d | wc -l)
  SKILL_COUNT=$((SKILL_COUNT - 1))
  echo "Copied $SKILL_COUNT built-in skills to skill-manager-skills/"
else
  echo "Warning: skill-manager-cli not found at: $SKILL_MGR_SRC"
  echo "Built-in skills will not be available."
  mkdir -p "$SKILL_EXPLORER_DIR/skill-manager-skills"
fi

echo "Preinstall complete."
