#!/bin/bash
# Skill Explorer Update Script
# Updates ploinky, demo repo, and restarts the router
#
# Usage: ./update.sh [--skip-npm] [--skip-restart]
#
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Parse arguments
SKIP_NPM=false
SKIP_RESTART=false

while [ $# -gt 0 ]; do
    case "$1" in
        --skip-npm)
            SKIP_NPM=true
            shift
            ;;
        --skip-restart)
            SKIP_RESTART=true
            shift
            ;;
        -h|--help)
            cat <<'EOF'
Usage: update.sh [OPTIONS]

Updates ploinky, demo repository, and restarts the router.

Options:
  --skip-npm       Skip npm install in ploinky directory
  --skip-restart   Skip ploinky restart after update
  -h, --help       Show this help message
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

log() {
    echo "[update] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

# Find ploinky installation directory
PLOINKY_BIN=$(which ploinky 2>/dev/null || true)
if [ -z "$PLOINKY_BIN" ]; then
    echo "ERROR: ploinky not found in PATH"
    exit 1
fi

# Resolve symlinks and get the actual ploinky directory
PLOINKY_BIN_REAL=$(readlink -f "$PLOINKY_BIN" 2>/dev/null || echo "$PLOINKY_BIN")
PLOINKY_DIR=$(dirname "$(dirname "$PLOINKY_BIN_REAL")")

log "Found ploinky at: $PLOINKY_BIN"
log "Ploinky directory: $PLOINKY_DIR"

# Step 1: Run npm install in ploinky directory
if [ "$SKIP_NPM" = "false" ]; then
    log "Running npm install in ploinky directory..."
    if [ -f "$PLOINKY_DIR/package.json" ]; then
        (cd "$PLOINKY_DIR" && npm install)
        log "npm install completed"
    else
        log "Warning: No package.json found in $PLOINKY_DIR, skipping npm install"
    fi
else
    log "Skipping npm install (--skip-npm)"
fi

# Step 2: Update demo repository
log "Updating demo repository..."
ploinky update repo demo
log "demo repository updated"

# Step 3: Update AssistOSExplorer repository (dependency)
log "Updating AssistOSExplorer repository..."
ploinky update repo AssistOSExplorer || log "Warning: AssistOSExplorer repo update failed (may not exist)"

# Step 4: Restart ploinky
if [ "$SKIP_RESTART" = "false" ]; then
    log "Restarting ploinky..."
    ploinky restart
    log "Ploinky restarted"
else
    log "Skipping restart (--skip-restart)"
fi

log "Update complete!"
