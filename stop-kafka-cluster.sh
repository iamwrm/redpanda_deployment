#!/bin/bash
# Stop Kafka cluster

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAFKA_HOME="$SCRIPT_DIR/kafka"

echo "Stopping Kafka brokers..."

# Stop all Kafka processes
pkill -f "kafka.Kafka" 2>/dev/null || true

echo "Kafka cluster stopped."
