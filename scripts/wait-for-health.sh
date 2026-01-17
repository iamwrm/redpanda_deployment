#!/bin/bash
set -euo pipefail

# Wait for Redpanda 3-node cluster to be healthy
# Usage: ./wait-for-health.sh [install_dir] [max_attempts]

INSTALL_DIR="${1:-$HOME/redpanda}"
MAX_ATTEMPTS="${2:-30}"
BROKERS="${REDPANDA_BROKERS:-127.0.0.1:19092}"

RPK_BIN="$INSTALL_DIR/opt/redpanda/libexec/rpk"

echo "=== Waiting for Redpanda cluster to be healthy ==="
echo "Brokers: $BROKERS"
echo "Max attempts: $MAX_ATTEMPTS"

for i in $(seq 1 "$MAX_ATTEMPTS"); do
    if "$RPK_BIN" cluster health -X brokers="$BROKERS" 2>/dev/null | grep -q "Healthy:.*true"; then
        echo ""
        echo "Cluster is healthy!"
        "$RPK_BIN" cluster health -X brokers="$BROKERS"
        exit 0
    fi
    echo "Waiting for cluster to become healthy... ($i/$MAX_ATTEMPTS)"
    sleep 2
done

echo ""
echo "ERROR: Cluster failed to become healthy after $MAX_ATTEMPTS attempts"
"$RPK_BIN" cluster health -X brokers="$BROKERS" || true
exit 1
