#!/bin/sh
# ============================================================================
# Skill Explorer Startup Script
# ============================================================================
# Starts all Skill Explorer containers in the correct order.
# Used by the systemd service for boot persistence.
# ============================================================================
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Add ploinky to PATH (systemd doesn't load user profile)
export PATH="$HOME/ploinky/bin:$HOME/.local/bin:$PATH"

log() {
    echo "[skill-explorer-startup] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

# Load environment if available
if [ -f "$SCRIPT_DIR/.env" ]; then
    log "Loading environment from $SCRIPT_DIR/.env"
    set -a
    . "$SCRIPT_DIR/.env"
    set +a
fi

# Configuration
CLOUDFLARE_TUNNEL_NAME="${CLOUDFLARE_TUNNEL_NAME:-skill-explorer}"
ROUTER_PORT="${ROUTER_PORT:-8888}"

log "Starting Skill Explorer services..."

# ============================================================================
# Start Cloudflared for skill-explorer
# ============================================================================
if podman ps -a --format '{{.Names}}' | grep -q '^cloudflared-skills$'; then
    log "Starting cloudflared-skills..."
    podman start cloudflared-skills 2>/dev/null || log "cloudflared-skills may already be running"
else
    log "cloudflared-skills container not found, attempting to create..."
    if [ -f "/etc/cloudflared-skills/config.yml" ] && [ -f "$HOME/.cloudflared/cert.pem" ]; then
        # Dynamically find tunnel ID by name
        log "Looking up tunnel ID for '${CLOUDFLARE_TUNNEL_NAME}'..."
        TUNNEL_LIST=$(podman run --rm --user 0 \
            -e HOME=/root \
            -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
            docker.io/cloudflare/cloudflared:latest \
            tunnel list --output json 2>/dev/null || echo "[]")

        CLOUDFLARE_TUNNEL_ID=$(echo "$TUNNEL_LIST" | jq -r ".[] | select(.name == \"${CLOUDFLARE_TUNNEL_NAME}\") | .id" 2>/dev/null || true)

        if [ -z "$CLOUDFLARE_TUNNEL_ID" ] || [ "$CLOUDFLARE_TUNNEL_ID" = "null" ]; then
            log "WARNING: Could not find tunnel '${CLOUDFLARE_TUNNEL_NAME}'"
        elif [ ! -f "$HOME/.cloudflared/${CLOUDFLARE_TUNNEL_ID}.json" ]; then
            log "WARNING: Credentials file not found for tunnel $CLOUDFLARE_TUNNEL_ID"
        else
            log "Found tunnel ID: $CLOUDFLARE_TUNNEL_ID"
            TOKEN=$(podman run --rm --user 0 \
                -e HOME=/root \
                -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
                docker.io/cloudflare/cloudflared:latest \
                tunnel token "$CLOUDFLARE_TUNNEL_ID" 2>/dev/null || true)

            if [ -n "$TOKEN" ]; then
                podman run -d \
                    --name cloudflared-skills \
                    --restart=always \
                    --read-only \
                    --cap-drop=ALL \
                    --security-opt no-new-privileges \
                    --network host \
                    -v /etc/cloudflared-skills:/etc/cloudflared:Z \
                    docker.io/cloudflare/cloudflared:latest \
                    tunnel --no-autoupdate run --token "$TOKEN"
                log "cloudflared-skills container created and started"
            else
                log "WARNING: Could not get tunnel token"
            fi
        fi
    else
        log "WARNING: /etc/cloudflared-skills/config.yml or ~/.cloudflared/cert.pem not found"
    fi
fi

# ============================================================================
# Start Skill Explorer Agent
# ============================================================================
cd "$SCRIPT_DIR"
log "Changed to directory: $(pwd)"

if command -v ploinky >/dev/null 2>&1; then
    log "Starting skill-explorer agent..."
    if ploinky start skill-explorer "$ROUTER_PORT" 2>&1; then
        log "ploinky start skill-explorer succeeded"
    else
        log "ploinky start skill-explorer failed, trying fallback..."
    fi
else
    log "Ploinky not found in PATH, trying fallback..."
fi

# Fallback: start containers directly by pattern matching
log "Checking for skill-explorer containers to start..."
for CONTAINER in $(podman ps -a --format '{{.Names}}' | grep -E "ploinky.*(skill-explorer|explorer|soplang|multimedia)" || true); do
    if [ -n "$CONTAINER" ]; then
        if podman ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
            log "$CONTAINER is already running"
        else
            log "Starting $CONTAINER..."
            podman start "$CONTAINER" 2>/dev/null && log "  Started successfully" || log "  Failed to start"
        fi
    fi
done

# ============================================================================
# Wait and verify
# ============================================================================
log "Waiting for services to initialize..."
sleep 5

log "Container status:"
podman ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep -E "(skill|cloudflared-skills)" || true

log "Skill Explorer startup complete."
