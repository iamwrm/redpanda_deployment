#!/bin/bash
set -euo pipefail

# Master script to run all Redpanda 3-node cluster tests
# Usage: ./test-all.sh [install_dir] [data_dir]
#
# This script will:
# 1. Download Redpanda (if not already present)
# 2. Start Redpanda 3-node cluster
# 3. Wait for cluster health
# 4. Run tests
# 5. Stop Redpanda (optional cleanup)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${1:-$HOME/redpanda}"
DATA_DIR="${2:-$HOME/redpanda-data}"

# Export for child scripts - use cluster endpoint (Node 1)
export REDPANDA_BROKERS="${REDPANDA_BROKERS:-127.0.0.1:19092}"

echo "========================================"
echo "  Redpanda 3-Node Cluster Test Suite"
echo "========================================"
echo "Install dir: $INSTALL_DIR"
echo "Data dir: $DATA_DIR"
echo "Brokers: $REDPANDA_BROKERS"
echo ""

# Step 1: Download Redpanda (if not present)
if [ ! -f "$INSTALL_DIR/opt/redpanda/libexec/redpanda" ]; then
    echo ">>> Step 1: Downloading Redpanda..."
    "$SCRIPT_DIR/download-redpanda.sh" "$INSTALL_DIR"
else
    echo ">>> Step 1: Redpanda already installed, skipping download"
fi
echo ""

# Step 2: Start Redpanda 3-node cluster
echo ">>> Step 2: Starting Redpanda 3-node cluster..."
"$SCRIPT_DIR/start-redpanda.sh" "$INSTALL_DIR" "$DATA_DIR"
echo ""

# Step 3: Wait for cluster health
echo ">>> Step 3: Waiting for cluster health..."
"$SCRIPT_DIR/wait-for-health.sh" "$INSTALL_DIR"
echo ""

# Step 4: Run tests
echo ">>> Step 4: Running tests..."
"$SCRIPT_DIR/run-tests.sh" "$INSTALL_DIR"
echo ""

echo "========================================"
echo "  All tests completed successfully!"
echo "========================================"
echo ""
echo "Redpanda 3-node cluster is still running. To stop it:"
echo "  $SCRIPT_DIR/stop-redpanda.sh $DATA_DIR"
