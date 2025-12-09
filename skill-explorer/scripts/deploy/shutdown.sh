#!/bin/sh
# ============================================================================
# Skill Explorer Shutdown Script
# ============================================================================
# Stops all Skill Explorer containers gracefully.
# Used by the systemd service for clean shutdown.
# ============================================================================
set -eu

log() {
    echo "[skill-explorer-shutdown] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

log "Stopping Skill Explorer services..."

# Stop skill-explorer and related containers (ploinky-managed)
for CONTAINER in $(podman ps --format '{{.Names}}' | grep -E "ploinky.*(skill-explorer|explorer|soplang|multimedia)" || true); do
    if [ -n "$CONTAINER" ]; then
        log "Stopping $CONTAINER..."
        podman stop -t 30 "$CONTAINER" 2>/dev/null || log "Warning: $CONTAINER stop timed out"
    fi
done

# Stop cloudflared-skills container
if podman ps --format '{{.Names}}' | grep -q '^cloudflared-skills$'; then
    log "Stopping cloudflared-skills..."
    podman stop -t 30 cloudflared-skills 2>/dev/null || log "Warning: cloudflared-skills stop timed out"
fi

log "Skill Explorer shutdown complete."
