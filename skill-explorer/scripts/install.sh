#!/bin/sh
# ============================================================================
# install.sh - Skill Explorer Container Installation Script
# ============================================================================
# This script runs inside the container during ploinky agent installation.
# It sets up dependencies and copies skill-manager built-in skills.
# ============================================================================
set -e

cd /code

echo "============================================"
echo "Installing skill-explorer..."
echo "============================================"

# Install npm dependencies
echo "Installing npm dependencies..."
npm install --production 2>/dev/null || npm install

# ============================================================================
# Copy skill-manager-cli built-in skills
# ============================================================================
# Try multiple possible locations for skill-manager source
SKILL_MGR_LOCATIONS="
/workspace/coralFlow/skill-manager-cli/skill-manager/src
/workspace/skill-manager-cli/skill-manager/src
/code/../skill-manager-cli/skill-manager/src
"

SKILL_MGR_SRC=""
for loc in $SKILL_MGR_LOCATIONS; do
  if [ -d "$loc/.AchillesSkills" ]; then
    SKILL_MGR_SRC="$loc"
    break
  fi
done

if [ -n "$SKILL_MGR_SRC" ]; then
  echo "Found skill-manager at: $SKILL_MGR_SRC"
  echo "Copying built-in skills..."

  # Copy built-in skills
  cp -r "$SKILL_MGR_SRC/.AchillesSkills" /code/skill-manager-skills

  # Copy supporting modules (optional, for advanced features)
  for module in repl ui schemas lib; do
    if [ -d "$SKILL_MGR_SRC/$module" ]; then
      cp -r "$SKILL_MGR_SRC/$module" /code/ 2>/dev/null || true
      echo "  Copied $module/"
    fi
  done
else
  echo "Warning: skill-manager-cli source not found"
  echo "Checked locations:"
  for loc in $SKILL_MGR_LOCATIONS; do
    echo "  - $loc"
  done
  echo ""
  echo "Built-in skills will not be available."
  echo "You can still create custom skills in .AchillesSkills/"
  mkdir -p /code/skill-manager-skills
fi

# ============================================================================
# Create directories
# ============================================================================
echo "Creating directories..."
mkdir -p /code/.AchillesSkills
mkdir -p /code/logs

# ============================================================================
# Make scripts executable
# ============================================================================
echo "Setting script permissions..."
chmod +x /code/tools/*.sh 2>/dev/null || true
chmod +x /code/scripts/*.sh 2>/dev/null || true
chmod +x /code/scripts/deploy/*.sh 2>/dev/null || true

# ============================================================================
# Verify installation
# ============================================================================
echo ""
echo "============================================"
echo "Installation complete!"
echo "============================================"
echo ""
echo "Directory structure:"
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
