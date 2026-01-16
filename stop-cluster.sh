#!/bin/bash
# Stop Redpanda cluster

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_DIR="$SCRIPT_DIR/redpanda-cluster"

if [ -f "$CLUSTER_DIR/pids.txt" ]; then
    PIDS=$(cat "$CLUSTER_DIR/pids.txt")
    echo "Stopping Redpanda nodes with PIDs: $PIDS"
    for pid in $PIDS; do
        if ps -p $pid > /dev/null 2>&1; then
            echo "Killing PID $pid..."
            kill $pid 2>/dev/null
        fi
    done
    rm -f "$CLUSTER_DIR/pids.txt"
    echo "Cluster stopped."
else
    echo "Stopping all redpanda processes..."
    pkill -f "redpanda.*--redpanda-cfg" 2>/dev/null || true
    echo "Done."
fi
