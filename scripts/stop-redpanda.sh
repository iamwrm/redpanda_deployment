#!/bin/bash
set -euo pipefail

# Stop Redpanda
# Usage: ./stop-redpanda.sh [data_dir]

DATA_DIR="${1:-$HOME/redpanda-data}"
PID_FILE="$DATA_DIR/redpanda.pid"

echo "=== Stopping Redpanda ==="

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    echo "Stopping Redpanda with PID: $PID"

    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null || true

        # Wait for graceful shutdown
        echo "Waiting for graceful shutdown..."
        for i in {1..30}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                echo "Redpanda stopped gracefully"
                rm -f "$PID_FILE"
                echo "=== Stopped ==="
                exit 0
            fi
            sleep 1
        done

        # Force kill if still running
        echo "Force killing PID $PID..."
        kill -9 "$PID" 2>/dev/null || true
        rm -f "$PID_FILE"
    else
        echo "PID $PID not running"
        rm -f "$PID_FILE"
    fi
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

echo "=== Stopped ==="
