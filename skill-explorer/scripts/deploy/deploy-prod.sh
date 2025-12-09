#!/bin/sh
# ============================================================================
# Unified Skill Explorer Production Deployment Script
# ============================================================================
# Deploys skill-explorer with its own Cloudflare tunnel at skills.axiologic.dev
#
# Usage: ./deploy-prod.sh [options]
#
# Options:
#   --skip-cloudflared      Skip Cloudflare tunnel setup
#   --skip-agent            Skip skill-explorer agent setup
#   -h, --help              Show this help message
#
# ============================================================================
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Source .bashrc BEFORE set -eu (bashrc may use unbound vars)
if [ -f "$HOME/.bashrc" ]; then
    set +eu
    . "$HOME/.bashrc"
    set +eu
fi

# Now enable strict mode
set -eu

# ============================================================================
# Configuration from environment (see env.example for required variables)
# ============================================================================
# Load .env if present
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    . "$SCRIPT_DIR/.env"
    set +a
fi

# Cloudflare Tunnel Configuration
CLOUDFLARE_TUNNEL_NAME="${CLOUDFLARE_TUNNEL_NAME:-skill-explorer}"

# Domain Configuration
SKILLS_HOSTNAME="${SKILLS_HOSTNAME:-skills.axiologic.dev}"

# Router Configuration
ROUTER_PORT="${ROUTER_PORT:-8888}"
ROUTER_URL="${PLOINKY_ROUTER_URL:-https://${SKILLS_HOSTNAME}}"

# Make /code writable in containers
export PLOINKY_CODE_WRITABLE=1

# ============================================================================
# Parse command line arguments
# ============================================================================
SKIP_CLOUDFLARED=false
SKIP_AGENT=false

while [ $# -gt 0 ]; do
    case "$1" in
        --skip-cloudflared)
            SKIP_CLOUDFLARED=true
            shift
            ;;
        --skip-agent)
            SKIP_AGENT=true
            shift
            ;;
        -h|--help)
            cat <<'EOF'
Usage: deploy-prod.sh [OPTIONS]

Unified Skill Explorer Production Deployment Script

Options:
  --skip-cloudflared      Skip Cloudflare tunnel setup
  --skip-agent            Skip skill-explorer agent setup
  -h, --help              Show this help message

Environment variables: See env.example for required configuration.
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# Helper Functions
# ============================================================================
log() {
    printf '[deploy] %s\n' "$*"
}

log_section() {
    echo ""
    echo "============================================================================"
    printf '  %s\n' "$*"
    echo "============================================================================"
    echo ""
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log "ERROR: Required command not found: $1"
        exit 1
    fi
}

# ============================================================================
# Pre-flight Checks
# ============================================================================
log_section "Pre-flight Checks"

check_command podman
check_command jq
check_command curl

# Check if ploinky is available (required for agent setup)
if [ "$SKIP_AGENT" = "false" ]; then
    check_command ploinky
fi

# Enable lingering for systemd user services
log "Enabling lingering for user $(whoami)..."
loginctl enable-linger "$(whoami)" 2>/dev/null || log "Warning: Could not enable lingering"

# ============================================================================
# PART 1: Cloudflare Tunnel Setup (separate tunnel for skill-explorer)
# ============================================================================
if [ "$SKIP_CLOUDFLARED" = "false" ]; then
    log_section "Setting up Cloudflare Tunnel for Skill Explorer"

    # Ensure .cloudflared directory exists
    mkdir -p "$HOME/.cloudflared"
    chmod 700 "$HOME/.cloudflared"

    CERT_FILE="$HOME/.cloudflared/cert.pem"

    # Step 1: Check if we're authenticated with Cloudflare
    if [ ! -f "$CERT_FILE" ]; then
        log "Cloudflare authentication required."
        log "Running 'cloudflared tunnel login'..."

        if ! podman run --rm -it --user 0 \
            -e HOME=/root \
            -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
            docker.io/cloudflare/cloudflared:latest \
            tunnel login; then
            log "ERROR: Cloudflare authentication failed."
            exit 1
        fi

        if [ ! -f "$CERT_FILE" ]; then
            log "ERROR: cert.pem was not created."
            exit 1
        fi
        log "Cloudflare authentication successful."
    else
        log "Cloudflare authentication found (cert.pem exists)."
    fi

    # Step 2: Check if tunnel exists or create it
    log "Checking for existing tunnel '${CLOUDFLARE_TUNNEL_NAME}'..."

    TUNNEL_LIST=$(podman run --rm --user 0 \
        -e HOME=/root \
        -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
        docker.io/cloudflare/cloudflared:latest \
        tunnel list --output json 2>/dev/null || echo "[]")

    EXISTING_TUNNEL_ID=$(echo "$TUNNEL_LIST" | jq -r ".[] | select(.name == \"${CLOUDFLARE_TUNNEL_NAME}\") | .id" 2>/dev/null || true)

    if [ -n "$EXISTING_TUNNEL_ID" ] && [ "$EXISTING_TUNNEL_ID" != "null" ]; then
        log "Found existing tunnel '${CLOUDFLARE_TUNNEL_NAME}' with ID: $EXISTING_TUNNEL_ID"
        CLOUDFLARE_TUNNEL_ID="$EXISTING_TUNNEL_ID"

        CRED_FILE="$HOME/.cloudflared/${CLOUDFLARE_TUNNEL_ID}.json"
        if [ ! -f "$CRED_FILE" ]; then
            log "WARNING: Credentials file not found. Deleting and recreating tunnel..."

            podman run --rm -it --user 0 \
                -e HOME=/root \
                -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
                docker.io/cloudflare/cloudflared:latest \
                tunnel delete "$CLOUDFLARE_TUNNEL_NAME" || true

            log "Creating new tunnel '${CLOUDFLARE_TUNNEL_NAME}'..."
            podman run --rm --user 0 \
                -e HOME=/root \
                -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
                docker.io/cloudflare/cloudflared:latest \
                tunnel create "$CLOUDFLARE_TUNNEL_NAME"

            TUNNEL_LIST=$(podman run --rm --user 0 \
                -e HOME=/root \
                -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
                docker.io/cloudflare/cloudflared:latest \
                tunnel list --output json 2>/dev/null || echo "[]")

            CLOUDFLARE_TUNNEL_ID=$(echo "$TUNNEL_LIST" | jq -r ".[] | select(.name == \"${CLOUDFLARE_TUNNEL_NAME}\") | .id" 2>/dev/null || true)
            log "Created new tunnel with ID: $CLOUDFLARE_TUNNEL_ID"
        fi
    else
        log "Tunnel '${CLOUDFLARE_TUNNEL_NAME}' not found. Creating..."

        podman run --rm --user 0 \
            -e HOME=/root \
            -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
            docker.io/cloudflare/cloudflared:latest \
            tunnel create "$CLOUDFLARE_TUNNEL_NAME"

        TUNNEL_LIST=$(podman run --rm --user 0 \
            -e HOME=/root \
            -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
            docker.io/cloudflare/cloudflared:latest \
            tunnel list --output json 2>/dev/null || echo "[]")

        CLOUDFLARE_TUNNEL_ID=$(echo "$TUNNEL_LIST" | jq -r ".[] | select(.name == \"${CLOUDFLARE_TUNNEL_NAME}\") | .id" 2>/dev/null || true)

        if [ -z "$CLOUDFLARE_TUNNEL_ID" ] || [ "$CLOUDFLARE_TUNNEL_ID" = "null" ]; then
            log "ERROR: Could not retrieve tunnel ID after creation."
            exit 1
        fi

        log "Created tunnel '${CLOUDFLARE_TUNNEL_NAME}' with ID: $CLOUDFLARE_TUNNEL_ID"
    fi

    CRED_FILE="$HOME/.cloudflared/${CLOUDFLARE_TUNNEL_ID}.json"
    log "Using credentials file: $CRED_FILE"

    # Ensure correct permissions
    chmod 600 "$HOME/.cloudflared"/*.json 2>/dev/null || true
    chmod 600 "$HOME/.cloudflared"/*.pem 2>/dev/null || true

    # Step 3: Get tunnel token
    log "Retrieving tunnel token..."
    TOKEN=$(podman run --rm --user 0 \
        -e HOME=/root \
        -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
        docker.io/cloudflare/cloudflared:latest \
        tunnel token "$CLOUDFLARE_TUNNEL_ID")
    echo "$TOKEN" | head -c 20 && echo '...'

    # Setup cloudflared config directory for skill-explorer
    log "Setting up /etc/cloudflared-skills..."
    sudo mkdir -p /etc/cloudflared-skills
    sudo cp "$HOME/.cloudflared/${CLOUDFLARE_TUNNEL_ID}.json" /etc/cloudflared-skills/
    sudo chmod 600 /etc/cloudflared-skills/*.json

    # Create cloudflared config for skill-explorer
    log "Creating cloudflared configuration..."
    sudo tee /etc/cloudflared-skills/config.yml >/dev/null <<YAML
tunnel: ${CLOUDFLARE_TUNNEL_ID}
credentials-file: /etc/cloudflared-skills/${CLOUDFLARE_TUNNEL_ID}.json
originRequest:
  http2Origin: true
  noTLSVerify: true
ingress:
  - hostname: ${SKILLS_HOSTNAME}
    service: http://127.0.0.1:${ROUTER_PORT}
  - service: http_status:404
YAML

    # Setup DNS route
    log "Setting up DNS route for ${SKILLS_HOSTNAME}..."
    podman run --rm -it --user 0 \
        -e HOME=/root \
        -v "$HOME/.cloudflared:/root/.cloudflared:Z" \
        docker.io/cloudflare/cloudflared:latest \
        tunnel route dns "$CLOUDFLARE_TUNNEL_NAME" "$SKILLS_HOSTNAME" || log "Warning: DNS route may already exist"

    # Stop existing cloudflared-skills container if running
    podman stop cloudflared-skills 2>/dev/null || true
    podman rm cloudflared-skills 2>/dev/null || true

    # Start cloudflared container for skill-explorer
    log "Starting cloudflared-skills container..."
    podman run -d \
        --name cloudflared-skills \
        --pull=always \
        --restart=always \
        --read-only \
        --cap-drop=ALL \
        --security-opt no-new-privileges \
        --network host \
        -v /etc/cloudflared-skills:/etc/cloudflared:Z \
        docker.io/cloudflare/cloudflared:latest \
        tunnel --no-autoupdate run --token "$TOKEN"

    log "Cloudflare tunnel setup complete for skill-explorer."
fi

# ============================================================================
# PART 2: Skill Explorer Agent Setup
# ============================================================================
if [ "$SKIP_AGENT" = "false" ]; then
    log_section "Setting up Skill Explorer Agent"

    # Detect container host
    if command -v podman >/dev/null 2>&1; then
        CONTAINER_HOST="host.containers.internal"
    elif command -v docker >/dev/null 2>&1; then
        CONTAINER_HOST="host.docker.internal"
    else
        CONTAINER_HOST="127.0.0.1"
    fi

    # Set ploinky variables
    log "Setting ploinky variables..."
    ploinky var PLOINKY_ROUTER_URL "$ROUTER_URL"
    log "Set PLOINKY_ROUTER_URL=$ROUTER_URL"

    # LLM API Keys
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        ploinky var OPENAI_API_KEY "$OPENAI_API_KEY"
        log "Set OPENAI_API_KEY from environment"
    fi

    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        ploinky var ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"
        log "Set ANTHROPIC_API_KEY from environment"
    fi

    if [ -n "${GEMINI_API_KEY:-}" ]; then
        ploinky var GEMINI_API_KEY "$GEMINI_API_KEY"
        log "Set GEMINI_API_KEY from environment"
    fi

    # Add demo repo if not already added
    log "Adding demo repository..."
    ploinky add repo demo https://github.com/PloinkyRepos/demo.git || true
    ploinky enable repo demo || true

    # Add AssistOSExplorer repo for file explorer
    log "Adding AssistOSExplorer repository..."
    ploinky add repo AssistOSExplorer https://github.com/PloinkyRepos/AssistOSExplorer.git || true
    ploinky enable repo AssistOSExplorer || true

    # Enable skill-explorer agent
    log "Enabling skill-explorer agent..."
    ploinky enable agent skill-explorer

    # Enable explorer agent as GLOBAL (uses workspace directory as root)
    log "Enabling explorer agent (global mode)..."
    ploinky enable agent explorer global

    # Set ASSISTOS_FS_ROOT to point to .AchillesSkills directory
    WORKSPACE_DIR=$(pwd)
    SKILL_EXPLORER_CODE="${WORKSPACE_DIR}/.ploinky/repos/demo/skill-explorer/.AchillesSkills"
    log "Setting ASSISTOS_FS_ROOT=${SKILL_EXPLORER_CODE}"
    ploinky var ASSISTOS_FS_ROOT "$SKILL_EXPLORER_CODE"

    # Make /code writable
    ploinky var PLOINKY_CODE_WRITABLE 1
    log "Set PLOINKY_CODE_WRITABLE=1"

    # Start the agent
    log "Starting skill-explorer agent on port $ROUTER_PORT..."
    ploinky start skill-explorer "$ROUTER_PORT"

    log "Skill Explorer agent setup complete."
fi

# ============================================================================
# Setup systemd service for auto-start on reboot
# ============================================================================
log_section "Setting up auto-start on reboot"

mkdir -p "$HOME/.config/systemd/user"

# Make scripts executable
chmod +x "$SCRIPT_DIR/startup.sh" "$SCRIPT_DIR/shutdown.sh" 2>/dev/null || true

# Create the skill-explorer systemd service
log "Creating skill-explorer.service..."
cat > "$HOME/.config/systemd/user/skill-explorer.service" <<EOF
[Unit]
Description=Skill Explorer Production Services
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${SCRIPT_DIR}
ExecStart=${SCRIPT_DIR}/startup.sh
ExecStop=${SCRIPT_DIR}/shutdown.sh
TimeoutStartSec=300
TimeoutStopSec=120

EnvironmentFile=-${SCRIPT_DIR}/.env

[Install]
WantedBy=default.target
EOF

log "Reloading systemd daemon..."
systemctl --user daemon-reload 2>/dev/null || true

log "Enabling skill-explorer.service..."
systemctl --user enable skill-explorer.service 2>/dev/null || true

# ============================================================================
# Summary
# ============================================================================
log_section "Deployment Complete"

echo "Services deployed:"
[ "$SKIP_CLOUDFLARED" = "false" ] && echo "  - Cloudflare Tunnel (cloudflared-skills)"
[ "$SKIP_AGENT" = "false" ] && echo "  - Skill Explorer Agent"

echo ""
echo "Boot persistence:"
echo "  - skill-explorer.service (manages containers)"

echo ""
echo "Access URLs:"
echo "  - External:   https://${SKILLS_HOSTNAME}"
echo "  - Webchat:    https://${SKILLS_HOSTNAME}/webchat"
echo "  - Dashboard:  https://${SKILLS_HOSTNAME}/dashboard"
echo ""
echo "Service management:"
echo "  systemctl --user status skill-explorer"
echo "  systemctl --user start skill-explorer"
echo "  systemctl --user stop skill-explorer"
echo ""
echo "Container status:"
podman ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | grep -E "(skill|cloudflared)" || true
echo ""
