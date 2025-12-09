#!/bin/sh

# ============================================================================
# startSkillExplorer.sh - Skill Explorer Agent Launcher
# ============================================================================
# This script launches the skill-explorer agent with environment variables
# loaded from the workspace's .ploinky/.secrets file.
#
# Usage (called by ploinky router):
#   /path/to/startSkillExplorer.sh [--sso-user=...] [--sso-roles=...] [other args]
#
# The script automatically detects the workspace directory from the
# current working directory and loads configuration from:
#   $WORKSPACE/.ploinky/.secrets
#
# To set variables via ploinky CLI (from workspace):
#   ploinky var OPENAI_API_KEY "sk-your-key"
#   ploinky var ANTHROPIC_API_KEY "sk-ant-your-key"
# ============================================================================

# Get the absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect workspace directory (prefer explicit hint, then search upwards)
INITIAL_WORKSPACE_DIR="${PLOINKY_WORKSPACE_DIR:-$(pwd)}"

find_workspace_root() {
    local current="$1"
    while [ -n "$current" ] && [ "$current" != "/" ]; do
        if [ -d "$current/.ploinky" ]; then
            echo "$current"
            return 0
        fi
        local parent="$(dirname "$current")"
        if [ "$parent" = "$current" ]; then
            break
        fi
        current="$parent"
    done
    echo "$1"
}

WORKSPACE_DIR="$(find_workspace_root "$INITIAL_WORKSPACE_DIR")"

# Path to workspace secrets file
SECRETS_FILE="$WORKSPACE_DIR/.ploinky/.secrets"

# Debug mode (set DEBUG=1 to see what's happening)
DEBUG="${DEBUG:-0}"

debug_log() {
    if [ "$DEBUG" = "1" ]; then
        echo "[startSkillExplorer.sh DEBUG] $*" >&2
    fi
}

# Path to main agent script (one level up from scripts/)
AGENT_MAIN="$(dirname "$SCRIPT_DIR")/main.mjs"
debug_log "Using skill-explorer agent"

# Suppress Node.js warnings (can be overridden by env)
export NODE_NO_WARNINGS="${NODE_NO_WARNINGS:-1}"

# Function to read a variable from the workspace .secrets file
read_secret() {
    local var_name="$1"
    if [ -f "$SECRETS_FILE" ]; then
        local value=$(grep "^${var_name}=" "$SECRETS_FILE" 2>/dev/null | head -n 1 | cut -d'=' -f2-)
        debug_log "read_secret($var_name): $value"
        echo "$value"
    else
        debug_log "read_secret($var_name): secrets file not found"
    fi
}

# Function to export variable from .secrets if not already set
export_from_secrets() {
    local var_name="$1"
    local current_value
    eval "current_value=\${$var_name:-}"

    if [ -z "$current_value" ]; then
        local secret_value=$(read_secret "$var_name")
        if [ -n "$secret_value" ]; then
            export "$var_name=$secret_value"
            debug_log "Exported $var_name from secrets"
        else
            debug_log "No value for $var_name in secrets"
        fi
    else
        debug_log "$var_name already set in environment"
    fi
}

# Verify agent main.mjs exists
if [ ! -f "$AGENT_MAIN" ]; then
    echo "ERROR: main.mjs not found at: $AGENT_MAIN" >&2
    echo "Make sure you're running this from the correct location." >&2
    exit 1
fi

# ============================================================================
# LLM Provider API Keys
# ============================================================================
export_from_secrets "OPENAI_API_KEY"
export_from_secrets "ANTHROPIC_API_KEY"
export_from_secrets "GEMINI_API_KEY"
export_from_secrets "MISTRAL_API_KEY"
export_from_secrets "DEEPSEEK_API_KEY"
export_from_secrets "OPENROUTER_API_KEY"
export_from_secrets "HUGGINGFACE_API_KEY"

# ============================================================================
# Agent Feedback Control
# ============================================================================
export_from_secrets "LLMAgentClient_DEBUG"
export_from_secrets "LLMAgentClient_VERBOSE_DELAY"

# ============================================================================
# Router Configuration
# ============================================================================
export_from_secrets "PLOINKY_ROUTER_URL"
export_from_secrets "PLOINKY_ROUTER_PORT"

# ============================================================================
# Debug Output
# ============================================================================
if [ "$DEBUG" = "1" ]; then
    echo "[startSkillExplorer.sh] Configuration:" >&2
    echo "  Agent Main: $AGENT_MAIN" >&2
    echo "  Workspace: $WORKSPACE_DIR" >&2
    echo "  Secrets file: $SECRETS_FILE" >&2
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        echo "  OPENAI_API_KEY: [set]" >&2
    else
        echo "  OPENAI_API_KEY: [not set]" >&2
    fi
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        echo "  ANTHROPIC_API_KEY: [set]" >&2
    else
        echo "  ANTHROPIC_API_KEY: [not set]" >&2
    fi
    echo "  Arguments: $@" >&2
fi

# ============================================================================
# Execute Agent
# ============================================================================
debug_log "Executing: node --no-warnings $AGENT_MAIN $@"
exec node --no-warnings "$AGENT_MAIN" "$@"
