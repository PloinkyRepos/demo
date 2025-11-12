#!/bin/sh
set -eu

now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat <<JSON
{
  "agent": "demo",
  "status": "ok",
  "timestamp": "$now"
}
JSON
