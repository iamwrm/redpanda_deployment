#!/bin/bash
# Start Redpanda 3-node cluster

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDPANDA_BIN="/opt/redpanda/libexec/redpanda"
CLUSTER_DIR="$SCRIPT_DIR/redpanda-cluster"

export LD_LIBRARY_PATH="/opt/redpanda/lib"
export PATH="/opt/redpanda/bin:$PATH"

echo "Starting Redpanda 3-node cluster..."

# Start Node 1 (seed node)
echo "Starting Node 1 (node_id=0)..."
$REDPANDA_BIN \
    --redpanda-cfg "$CLUSTER_DIR/node1/redpanda.yaml" \
    start &
NODE1_PID=$!
echo "Node 1 started with PID: $NODE1_PID"

# Wait for seed node to be ready
sleep 5

# Start Node 2
echo "Starting Node 2 (node_id=1)..."
$REDPANDA_BIN \
    --redpanda-cfg "$CLUSTER_DIR/node2/redpanda.yaml" \
    start &
NODE2_PID=$!
echo "Node 2 started with PID: $NODE2_PID"

# Start Node 3
echo "Starting Node 3 (node_id=2)..."
$REDPANDA_BIN \
    --redpanda-cfg "$CLUSTER_DIR/node3/redpanda.yaml" \
    start &
NODE3_PID=$!
echo "Node 3 started with PID: $NODE3_PID"

echo ""
echo "All nodes started!"
echo "PIDs: Node1=$NODE1_PID, Node2=$NODE2_PID, Node3=$NODE3_PID"
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

# Save PIDs to file
echo "$NODE1_PID $NODE2_PID $NODE3_PID" > "$CLUSTER_DIR/pids.txt"

wait
