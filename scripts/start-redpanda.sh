#!/bin/bash
set -euo pipefail

# Start Redpanda server
# Usage: ./start-redpanda.sh [install_dir] [data_dir]

INSTALL_DIR="${1:-$HOME/redpanda}"
DATA_DIR="${2:-$HOME/redpanda-data}"
CONFIG_FILE="${DATA_DIR}/redpanda.yaml"

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

# Create config file
echo "Creating config at $CONFIG_FILE..."
cat > "$CONFIG_FILE" <<EOF
redpanda:
  data_directory: $DATA_DIR
  node_id: 0
  seed_servers: []
  rpc_server:
    address: 127.0.0.1
    port: 33145
  kafka_api:
    - address: 127.0.0.1
      port: 9092
  admin:
    - address: 127.0.0.1
      port: 9644
  developer_mode: true
EOF

echo "Starting Redpanda in background..."

# Use bundled dynamic linker to run redpanda
"$REDPANDA_LD" \
    --library-path "$REDPANDA_LIB" \
    "$REDPANDA_BIN" \
    --redpanda-cfg "$CONFIG_FILE" \
    --smp 1 \
    --memory 1G \
    --reserve-memory 0M \
    --overprovisioned \
    --unsafe-bypass-fsync 1 \
    --lock-memory false \
    &

REDPANDA_PID=$!
echo "Redpanda started with PID: $REDPANDA_PID"
echo "$REDPANDA_PID" > "$DATA_DIR/redpanda.pid"

echo "Waiting for initial startup..."
sleep 10

echo "=== Redpanda started ==="
echo "PID file: $DATA_DIR/redpanda.pid"
echo "Kafka API: 127.0.0.1:9092"
echo "Admin API: 127.0.0.1:9644"
