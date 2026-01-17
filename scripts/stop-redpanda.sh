#!/bin/bash
set -euo pipefail

# Stop Redpanda server
# Usage: ./stop-redpanda.sh [data_dir]

DATA_DIR="${1:-$HOME/redpanda-data}"
PID_FILE="$DATA_DIR/redpanda.pid"

echo "=== Stopping Redpanda ==="

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping Redpanda (PID: $PID)..."
        kill "$PID"

        # Wait for graceful shutdown
        for i in {1..30}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                echo "Redpanda stopped gracefully"
                rm -f "$PID_FILE"
                exit 0
            fi
            sleep 1
        done

        # Force kill if still running
        echo "Force killing Redpanda..."
        kill -9 "$PID" 2>/dev/null || true
        rm -f "$PID_FILE"
    else
        echo "Redpanda process not running (stale PID file)"
        rm -f "$PID_FILE"
    fi
else
    echo "No PID file found at $PID_FILE"
    echo "Trying to find redpanda process..."

    # Try to find and kill any redpanda process
    if pgrep -f "redpanda.*--redpanda-cfg" > /dev/null; then
        pkill -f "redpanda.*--redpanda-cfg"
        echo "Killed redpanda process"
    else
        echo "No redpanda process found"
    fi
fi

echo "=== Redpanda stopped ==="
