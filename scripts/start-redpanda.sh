#!/bin/bash
set -euo pipefail

# Start Redpanda (single node with cluster-compatible ports)
# Usage: ./start-redpanda.sh [install_dir] [data_dir]
#
# This script starts a single Redpanda node using the same ports as
# the main directory's 3-node cluster setup (Node 1 ports) for compatibility.

INSTALL_DIR="${1:-$HOME/redpanda}"
DATA_DIR="${2:-$HOME/redpanda-data}"

REDPANDA_BIN="$INSTALL_DIR/opt/redpanda/libexec/redpanda"
REDPANDA_LD="$INSTALL_DIR/opt/redpanda/lib/ld.so"
REDPANDA_LIB="$INSTALL_DIR/opt/redpanda/lib"

echo "=== Starting Redpanda ==="
echo "Install dir: $INSTALL_DIR"
echo "Data dir: $DATA_DIR"

# Check if redpanda binary exists
if [ ! -f "$REDPANDA_BIN" ]; then
    echo "ERROR: Redpanda binary not found at $REDPANDA_BIN"
    echo "Run ./download-redpanda.sh first"
    exit 1
fi

# Create data directory
mkdir -p "$DATA_DIR"

# Create config file (using cluster-compatible ports: 19092, 19644)
echo "Creating config at $DATA_DIR/redpanda.yaml..."
cat > "$DATA_DIR/redpanda.yaml" <<EOF
redpanda:
    data_directory: $DATA_DIR/data
    node_id: 0
    seed_servers: []
    rpc_server:
        address: 0.0.0.0
        port: 33145
    kafka_api:
        - address: 0.0.0.0
          port: 19092
    admin:
        - address: 0.0.0.0
          port: 19644
    developer_mode: true
rpk:
    kafka_api:
        brokers:
            - 127.0.0.1:19092
    admin_api:
        addresses:
            - 127.0.0.1:19644
    overprovisioned: true
pandaproxy: {}
schema_registry: {}
EOF

# Start Redpanda in background
echo "Starting Redpanda in background..."
"$REDPANDA_LD" \
    --library-path "$REDPANDA_LIB" \
    "$REDPANDA_BIN" \
    --redpanda-cfg "$DATA_DIR/redpanda.yaml" \
    --smp 1 \
    --memory 1G \
    --reserve-memory 0M \
    --overprovisioned \
    --unsafe-bypass-fsync 1 \
    --lock-memory false \
    &
REDPANDA_PID=$!
echo "Redpanda started with PID: $REDPANDA_PID"

# Save PID to file
echo "$REDPANDA_PID" > "$DATA_DIR/redpanda.pid"

echo ""
echo "=== Redpanda started ==="
echo "Kafka API: 127.0.0.1:19092"
echo "Admin API: 127.0.0.1:19644"
echo "PID file: $DATA_DIR/redpanda.pid"
echo ""
echo "Waiting for initial startup..."
sleep 10
echo "=== Startup complete ==="
