#!/bin/sh
set -eu

# Load the TLS mitigation before telemetry and application code, preserving any
# NODE_OPTIONS supplied by existing deployments, even with an overridden CMD.
export NODE_OPTIONS="--import=/app/emudhra-preload.mjs${NODE_OPTIONS:+ $NODE_OPTIONS}"

exec "$@"
