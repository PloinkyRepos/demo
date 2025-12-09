#!/bin/sh
# ============================================================================
# Skill Explorer Development Deployment Script
# ============================================================================
# This script sets up skill-explorer for local development.
#
# Usage: ./deploy-dev.sh [options]
#
# Options:
#   --port <port>    Router port (default: 8080)
#   --skip-vars      Skip setting ploinky variables
#   --with-explorer  Also enable the file explorer agent
#
# Prerequisites:
#   - ploinky CLI installed
#   - An LLM API key (OPENAI_API_KEY or ANTHROPIC_API_KEY)
#
# ============================================================================
set -eu
export PLOINKY_CODE_WRITABLE=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_EXPLORER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ============================================================================
# Configuration
# ============================================================================
# Load .env if present
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    . "$SCRIPT_DIR/.env"
    set +a
fi

# Make /code writable in containers (allows skill file editing)
export PLOINKY_CODE_WRITABLE=1

# Default port
ROUTER_PORT="${ROUTER_PORT:-8080}"

# ============================================================================
# Parse Arguments
# ============================================================================
SKIP_VARS="false"
WITH_EXPLORER="false"

while [ $# -gt 0 ]; do
    case "$1" in
        --port)
            ROUTER_PORT="$2"
            shift 2
            ;;
        --skip-vars)
            SKIP_VARS="true"
            shift
            ;;
        --with-explorer)
            WITH_EXPLORER="true"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --port <port>    Router port (default: 8080)"
            echo "  --skip-vars      Skip setting ploinky variables"
            echo "  --with-explorer  Also enable the file explorer agent"
            echo ""
            echo "Environment Variables:"
            echo "  OPENAI_API_KEY      OpenAI API key"
            echo "  ANTHROPIC_API_KEY   Anthropic API key"
            echo ""
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
    echo "[deploy-dev] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

# ============================================================================
# Check Prerequisites
# ============================================================================
log "Checking prerequisites..."

if ! command -v ploinky >/dev/null 2>&1; then
    log "ERROR: ploinky CLI not found. Please install ploinky first."
    exit 1
fi

# Detect container runtime for router URL
if command -v podman >/dev/null 2>&1; then
    CONTAINER_HOST="host.containers.internal"
    CONTAINER_CMD="podman"
    log "Using Podman (host: $CONTAINER_HOST)"
elif command -v docker >/dev/null 2>&1; then
    CONTAINER_HOST="host.docker.internal"
    CONTAINER_CMD="docker"
    log "Using Docker (host: $CONTAINER_HOST)"
else
    CONTAINER_HOST="127.0.0.1"
    CONTAINER_CMD=""
    log "No container runtime detected, using localhost"
fi

# ============================================================================
# Set Ploinky Variables
# ============================================================================
if [ "$SKIP_VARS" = "false" ]; then
    log "============================================"
    log "Setting up ploinky variables..."
    log "============================================"

    # Router URL
    ROUTER_URL="${PLOINKY_ROUTER_URL:-http://${CONTAINER_HOST}:${ROUTER_PORT}}"
    ploinky var PLOINKY_ROUTER_URL "$ROUTER_URL"
    log "Set PLOINKY_ROUTER_URL=$ROUTER_URL"

    # LLM API Keys - only set if provided
    if [ -n "${OPENAI_API_KEY:-}" ] && [ "$OPENAI_API_KEY" != "sk-your-api-key-here" ]; then
        ploinky var OPENAI_API_KEY "$OPENAI_API_KEY"
        log "Set OPENAI_API_KEY from environment"
    fi

    if [ -n "${ANTHROPIC_API_KEY:-}" ] && [ "$ANTHROPIC_API_KEY" != "sk-ant-your-key" ]; then
        ploinky var ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"
        log "Set ANTHROPIC_API_KEY from environment"
    fi

    if [ -n "${GEMINI_API_KEY:-}" ]; then
        ploinky var GEMINI_API_KEY "$GEMINI_API_KEY"
        log "Set GEMINI_API_KEY from environment"
    fi

    if [ -n "${MISTRAL_API_KEY:-}" ]; then
        ploinky var MISTRAL_API_KEY "$MISTRAL_API_KEY"
        log "Set MISTRAL_API_KEY from environment"
    fi

    if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
        ploinky var DEEPSEEK_API_KEY "$DEEPSEEK_API_KEY"
        log "Set DEEPSEEK_API_KEY from environment"
    fi

    if [ -n "${OPENROUTER_API_KEY:-}" ]; then
        ploinky var OPENROUTER_API_KEY "$OPENROUTER_API_KEY"
        log "Set OPENROUTER_API_KEY from environment"
    fi
fi

# ============================================================================
# Add and Enable Repository
# ============================================================================
log "============================================"
log "Setting up skill-explorer agent..."
log "============================================"

# Add demo repo from GitHub
log "Adding demo repository..."
ploinky add repo demo https://github.com/PloinkyRepos/demo.git
ploinky enable repo demo

# Enable skill-explorer agent
log "Enabling skill-explorer agent..."
ploinky enable agent skill-explorer

# Make /code writable in containers (allows skill file editing)
# This MUST be set AFTER repos are added/enabled but BEFORE start
ploinky var PLOINKY_CODE_WRITABLE 1
log "Set PLOINKY_CODE_WRITABLE=1 for development"

# Optionally enable explorer
if [ "$WITH_EXPLORER" = "true" ]; then
    log "Enabling file explorer agent..."
    ploinky enable agent AssistOSExplorer/explorer || ploinky enable agent explorer || true
fi

# ============================================================================
# Start the Agent
# ============================================================================
log "Starting skill-explorer agent..."
ploinky start skill-explorer "$ROUTER_PORT"

# ============================================================================
# Summary
# ============================================================================
log "============================================"
log "Skill Explorer Deployment Complete!"
log "============================================"
log ""
log "Access the application at:"
log "  Webchat:    http://127.0.0.1:${ROUTER_PORT}/webchat"
log "  Dashboard:  http://127.0.0.1:${ROUTER_PORT}/dashboard"
log "  MCP:        http://127.0.0.1:${ROUTER_PORT}/mcps/skill-explorer/mcp"
log ""
log "Quick commands:"
log "  ploinky cli skill-explorer   # Interactive CLI"
log "  ploinky status               # Check status"
log "  ploinky stop skill-explorer  # Stop agent"
log ""

# Show status
log "Agent status:"
ploinky status 2>/dev/null || true
