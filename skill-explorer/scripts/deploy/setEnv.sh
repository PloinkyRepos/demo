#!/bin/sh
# ============================================================================
# setEnv.sh - Set Environment Variables for skill-explorer
# ============================================================================
# Source this file to set up environment variables for skill-explorer.
#
# Usage:
#   source ./setEnv.sh
#   # or
#   . ./setEnv.sh
#
# This will prompt for any missing API keys and set ploinky variables.
# ============================================================================

# Detect container runtime for router URL
if command -v podman >/dev/null 2>&1; then
    CONTAINER_HOST="host.containers.internal"
elif command -v docker >/dev/null 2>&1; then
    CONTAINER_HOST="host.docker.internal"
else
    CONTAINER_HOST="127.0.0.1"
fi

# Router Configuration
ROUTER_PORT="${ROUTER_PORT:-8080}"
ROUTER_URL="${PLOINKY_ROUTER_URL:-http://${CONTAINER_HOST}:${ROUTER_PORT}}"

echo "Setting ploinky variables..."

# Router URL
ploinky var PLOINKY_ROUTER_URL "$ROUTER_URL"
echo "  PLOINKY_ROUTER_URL=$ROUTER_URL"

# Make /code writable
ploinky var PLOINKY_CODE_WRITABLE 1
echo "  PLOINKY_CODE_WRITABLE=1"

# LLM API Keys
if [ -n "${OPENAI_API_KEY:-}" ]; then
    ploinky var OPENAI_API_KEY "$OPENAI_API_KEY"
    echo "  OPENAI_API_KEY=[set from environment]"
else
    echo "  OPENAI_API_KEY=[not set - use: ploinky var OPENAI_API_KEY 'your-key']"
fi

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    ploinky var ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"
    echo "  ANTHROPIC_API_KEY=[set from environment]"
else
    echo "  ANTHROPIC_API_KEY=[not set - use: ploinky var ANTHROPIC_API_KEY 'your-key']"
fi

if [ -n "${GEMINI_API_KEY:-}" ]; then
    ploinky var GEMINI_API_KEY "$GEMINI_API_KEY"
    echo "  GEMINI_API_KEY=[set from environment]"
fi

if [ -n "${MISTRAL_API_KEY:-}" ]; then
    ploinky var MISTRAL_API_KEY "$MISTRAL_API_KEY"
    echo "  MISTRAL_API_KEY=[set from environment]"
fi

if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
    ploinky var DEEPSEEK_API_KEY "$DEEPSEEK_API_KEY"
    echo "  DEEPSEEK_API_KEY=[set from environment]"
fi

if [ -n "${OPENROUTER_API_KEY:-}" ]; then
    ploinky var OPENROUTER_API_KEY "$OPENROUTER_API_KEY"
    echo "  OPENROUTER_API_KEY=[set from environment]"
fi

echo ""
echo "Environment configured. You can now run:"
echo "  ploinky enable agent demo/skill-explorer"
echo "  ploinky start skill-explorer"
