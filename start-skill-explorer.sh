#!/bin/sh
# Make /code writable in containers (allows skill file editing)
# This MUST be set AFTER repos are added/enabled but BEFORE start
ploinky var PLOINKY_CODE_WRITABLE 1
log "Set PLOINKY_CODE_WRITABLE=1 for development"

# ============================================================================
# Start the Agent
# ============================================================================
log "Starting skill-explorer agent..."
ploinky start skill-explorer "$ROUTER_PORT"
ploinky vars

