#!/bin/bash
set -euo pipefail

# Start Redpanda 3-node cluster
# Usage: ./start-redpanda.sh [install_dir] [data_dir]

INSTALL_DIR="${1:-$HOME/redpanda}"
DATA_DIR="${2:-$HOME/redpanda-data}"
CLUSTER_DIR="$DATA_DIR/cluster"

REDPANDA_BIN="$INSTALL_DIR/opt/redpanda/libexec/redpanda"
REDPANDA_LD="$INSTALL_DIR/opt/redpanda/lib/ld.so"
REDPANDA_LIB="$INSTALL_DIR/opt/redpanda/lib"

echo "=== Starting Redpanda 3-node cluster ==="
echo "Install dir: $INSTALL_DIR"
echo "Data dir: $DATA_DIR"

# Check if redpanda binary exists
if [ ! -f "$REDPANDA_BIN" ]; then
    echo "ERROR: Redpanda binary not found at $REDPANDA_BIN"
    echo "Run ./download-redpanda.sh first"
    exit 1
fi

# Create cluster directories
mkdir -p "$CLUSTER_DIR/node1/data"
mkdir -p "$CLUSTER_DIR/node2/data"
mkdir -p "$CLUSTER_DIR/node3/data"

# Create Node 1 config (seed node)
echo "Creating Node 1 config..."
cat > "$CLUSTER_DIR/node1/redpanda.yaml" <<EOF
redpanda:
  data_directory: $CLUSTER_DIR/node1/data
  node_id: 0
  empty_seed_starts_cluster: true
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
  advertised_rpc_api:
    address: 127.0.0.1
    port: 33145
  advertised_kafka_api:
    - address: 127.0.0.1
      port: 19092
  developer_mode: true
  auto_create_topics_enabled: true
  fetch_reads_debounce_timeout: 10
  group_initial_rebalance_delay: 0
  group_topic_partitions: 3
  log_segment_size_min: 1
  storage_min_free_bytes: 10485760
  topic_partitions_per_shard: 1000
  write_caching_default: "true"
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

# Create Node 2 config
echo "Creating Node 2 config..."
cat > "$CLUSTER_DIR/node2/redpanda.yaml" <<EOF
redpanda:
  data_directory: $CLUSTER_DIR/node2/data
  node_id: 1
  empty_seed_starts_cluster: false
  seed_servers:
    - host:
        address: 127.0.0.1
        port: 33145
  rpc_server:
    address: 0.0.0.0
    port: 33146
  kafka_api:
    - address: 0.0.0.0
      port: 29092
  admin:
    - address: 0.0.0.0
      port: 29644
  advertised_rpc_api:
    address: 127.0.0.1
    port: 33146
  advertised_kafka_api:
    - address: 127.0.0.1
      port: 29092
  developer_mode: true
rpk:
  kafka_api:
    brokers:
      - 127.0.0.1:19092
      - 127.0.0.1:29092
      - 127.0.0.1:39092
  admin_api:
    addresses:
      - 127.0.0.1:29644
  overprovisioned: true
pandaproxy: {}
schema_registry: {}
EOF

# Create Node 3 config
echo "Creating Node 3 config..."
cat > "$CLUSTER_DIR/node3/redpanda.yaml" <<EOF
redpanda:
  data_directory: $CLUSTER_DIR/node3/data
  node_id: 2
  empty_seed_starts_cluster: false
  seed_servers:
    - host:
        address: 127.0.0.1
        port: 33145
  rpc_server:
    address: 0.0.0.0
    port: 33147
  kafka_api:
    - address: 0.0.0.0
      port: 39092
  admin:
    - address: 0.0.0.0
      port: 39644
  advertised_rpc_api:
    address: 127.0.0.1
    port: 33147
  advertised_kafka_api:
    - address: 127.0.0.1
      port: 39092
  developer_mode: true
rpk:
  kafka_api:
    brokers:
      - 127.0.0.1:19092
      - 127.0.0.1:29092
      - 127.0.0.1:39092
  admin_api:
    addresses:
      - 127.0.0.1:39644
  overprovisioned: true
pandaproxy: {}
schema_registry: {}
EOF

# Common options for all nodes
COMMON_OPTS="--smp 1 --memory 512M --reserve-memory 0M --overprovisioned --unsafe-bypass-fsync 1 --lock-memory false"

# Start Node 1 (seed node)
echo "Starting Node 1 (node_id=0, seed node)..."
"$REDPANDA_LD" \
    --library-path "$REDPANDA_LIB" \
    "$REDPANDA_BIN" \
    --redpanda-cfg "$CLUSTER_DIR/node1/redpanda.yaml" \
    $COMMON_OPTS \
    &
NODE1_PID=$!
echo "Node 1 started with PID: $NODE1_PID"

# Wait for seed node to be ready
echo "Waiting for seed node to initialize..."
sleep 5

# Start Node 2
echo "Starting Node 2 (node_id=1)..."
"$REDPANDA_LD" \
    --library-path "$REDPANDA_LIB" \
    "$REDPANDA_BIN" \
    --redpanda-cfg "$CLUSTER_DIR/node2/redpanda.yaml" \
    $COMMON_OPTS \
    &
NODE2_PID=$!
echo "Node 2 started with PID: $NODE2_PID"

# Start Node 3
echo "Starting Node 3 (node_id=2)..."
"$REDPANDA_LD" \
    --library-path "$REDPANDA_LIB" \
    "$REDPANDA_BIN" \
    --redpanda-cfg "$CLUSTER_DIR/node3/redpanda.yaml" \
    $COMMON_OPTS \
    &
NODE3_PID=$!
echo "Node 3 started with PID: $NODE3_PID"

# Save PIDs to file
echo "$NODE1_PID $NODE2_PID $NODE3_PID" > "$CLUSTER_DIR/pids.txt"

echo ""
echo "=== Redpanda 3-node cluster started ==="
echo "PIDs: Node1=$NODE1_PID, Node2=$NODE2_PID, Node3=$NODE3_PID"
echo "PID file: $CLUSTER_DIR/pids.txt"
echo ""
echo "Kafka API endpoints:"
echo "  - Node 1: 127.0.0.1:19092"
echo "  - Node 2: 127.0.0.1:29092"
echo "  - Node 3: 127.0.0.1:39092"
echo ""
echo "Admin API endpoints:"
echo "  - Node 1: 127.0.0.1:19644"
echo "  - Node 2: 127.0.0.1:29644"
echo "  - Node 3: 127.0.0.1:39644"
echo ""
echo "Waiting for initial cluster formation..."
sleep 10
echo "=== Cluster startup complete ==="
