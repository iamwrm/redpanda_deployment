#!/bin/bash
set -euo pipefail

# Stop Redpanda 3-node cluster
# Usage: ./stop-redpanda.sh [data_dir]

DATA_DIR="${1:-$HOME/redpanda-data}"
CLUSTER_DIR="$DATA_DIR/cluster"
PID_FILE="$CLUSTER_DIR/pids.txt"

echo "=== Stopping Redpanda 3-node cluster ==="

if [ -f "$PID_FILE" ]; then
    PIDS=$(cat "$PID_FILE")
    echo "Stopping Redpanda nodes with PIDs: $PIDS"

    for pid in $PIDS; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "Stopping PID $pid..."
            kill "$pid" 2>/dev/null || true
        else
            echo "PID $pid not running"
        fi
    done

    # Wait for graceful shutdown
    echo "Waiting for graceful shutdown..."
    for i in {1..30}; do
        all_stopped=true
        for pid in $PIDS; do
            if kill -0 "$pid" 2>/dev/null; then
                all_stopped=false
                break
            fi
        done

        if $all_stopped; then
            echo "All nodes stopped gracefully"
            rm -f "$PID_FILE"
            echo "=== Cluster stopped ==="
            exit 0
        fi
        sleep 1
    done

    # Force kill if still running
    echo "Force killing remaining processes..."
    for pid in $PIDS; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "Force killing PID $pid..."
            kill -9 "$pid" 2>/dev/null || true
        fi
    done
    rm -f "$PID_FILE"
else
    echo "No PID file found at $PID_FILE"
    echo "Trying to find redpanda processes..."

    # Try to find and kill any redpanda process
    if pgrep -f "redpanda.*--redpanda-cfg" > /dev/null; then
        pkill -f "redpanda.*--redpanda-cfg"
        echo "Killed redpanda processes"
    else
        echo "No redpanda processes found"
    fi
fi

echo "=== Cluster stopped ==="
