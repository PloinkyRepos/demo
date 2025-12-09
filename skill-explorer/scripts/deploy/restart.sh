#!/bin/bash
# Restart script for skill-explorer development
# This script copies uncommitted changes from the demo source
# to the ploinky repos directory and restarts the agent.
#
# Usage: ./restart.sh [options]
#
# Options:
#   --no-copy         Skip copying files, just restart agent
#   -h, --help        Show this help message
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$SCRIPT_DIR"

# Make /code writable in containers (allows skill file editing)
export PLOINKY_CODE_WRITABLE=1

# Source location (where you develop the code)
DEMO_SOURCE="${DEMO_SOURCE:-/home/apparatus/work/file-parser/coralFlow/demo}"
SKILL_MANAGER_SOURCE="${SKILL_MANAGER_SOURCE:-/home/apparatus/work/file-parser/coralFlow/skill-manager-cli/skill-manager/src/.AchillesSkills}"

# Ploinky repos directory (where ploinky expects the code)
PLOINKY_REPOS_DIR="${WORKSPACE_DIR}/.ploinky/repos"

# Parse arguments
DO_COPY="true"

while [ $# -gt 0 ]; do
    case "$1" in
        --no-copy)
            DO_COPY="false"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Restart skill-explorer with latest local changes."
            echo ""
            echo "Options:"
            echo "  --no-copy           Skip copying files, just restart agent"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  DEMO_SOURCE           Path to demo source (default: /home/apparatus/work/file-parser/coralFlow/demo)"
            echo "  SKILL_MANAGER_SOURCE  Path to skill-manager skills (default: /home/apparatus/work/file-parser/coralFlow/skill-manager-cli/skill-manager/src/.AchillesSkills)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

log() {
    echo "[restart] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

# Verify workspace exists
if [ ! -d "${WORKSPACE_DIR}/.ploinky" ]; then
    log "ERROR: Ploinky workspace not found at ${WORKSPACE_DIR}/.ploinky"
    log "Please run deploy-dev.sh first to initialize the workspace."
    exit 1
fi

if [ "$DO_COPY" = "true" ]; then
    # Copy demo repository (contains skill-explorer)
    if [ -d "$DEMO_SOURCE" ]; then
        log "Copying demo from ${DEMO_SOURCE}..."
        rm -rf "${PLOINKY_REPOS_DIR}/demo"
        cp -a "$DEMO_SOURCE" "${PLOINKY_REPOS_DIR}/"
        log "demo copied successfully."
    else
        log "WARNING: demo source not found at ${DEMO_SOURCE}"
        log "Skipping demo copy. Set DEMO_SOURCE to the correct path."
    fi

    # Copy skill-manager built-in skills to skill-explorer
    if [ -d "$SKILL_MANAGER_SOURCE" ]; then
        SKILL_EXPLORER_DIR="${PLOINKY_REPOS_DIR}/demo/skill-explorer"
        log "Copying skill-manager skills to skill-explorer..."
        rm -rf "${SKILL_EXPLORER_DIR}/skill-manager-skills"
        cp -a "$SKILL_MANAGER_SOURCE" "${SKILL_EXPLORER_DIR}/skill-manager-skills"
        # Remove skills-orchestrator from built-in (it's in .AchillesSkills)
        rm -rf "${SKILL_EXPLORER_DIR}/skill-manager-skills/skills-orchestrator" 2>/dev/null || true
        log "skill-manager skills copied successfully."
    else
        log "WARNING: skill-manager source not found at ${SKILL_MANAGER_SOURCE}"
        log "Built-in skills will not be available."
    fi
fi

# Change to workspace directory for ploinky commands
cd "$WORKSPACE_DIR"

# Set variables before restart
ploinky var PLOINKY_CODE_WRITABLE 1

# Set explorer root to .AchillesSkills directory
ploinky var ASSISTOS_FS_ROOT "${WORKSPACE_DIR}/.ploinky/repos/demo/skill-explorer/.AchillesSkills"

# Restart explorer to pick up new root
log "Restarting explorer with new root..."
ploinky restart explorer 2>/dev/null || true

# Restart skill-explorer agent
log "Restarting skill-explorer..."
ploinky restart skill-explorer || log "WARNING: skill-explorer restart failed (may not be running)"

log "============================================"
log "Restart complete!"
log "============================================"
log ""
log "You can view logs with:"
log "  ploinky logs skill-explorer"
log ""
log "Access the application at:"
log "  Webchat:    http://127.0.0.1:8080/webchat"
log "  Dashboard:  http://127.0.0.1:8080/dashboard"
