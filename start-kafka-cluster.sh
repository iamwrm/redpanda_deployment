#!/bin/bash
# Start Kafka 3-broker KRaft cluster

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAFKA_HOME="$SCRIPT_DIR/kafka"
CLUSTER_DIR="$SCRIPT_DIR/kafka-cluster"

echo "Starting Kafka 3-broker KRaft cluster..."

# Start Broker 1
echo "Starting Broker 1 (node.id=1)..."
$KAFKA_HOME/bin/kafka-server-start.sh -daemon $CLUSTER_DIR/broker1/server.properties
echo "Broker 1 starting..."

sleep 2

# Start Broker 2
echo "Starting Broker 2 (node.id=2)..."
$KAFKA_HOME/bin/kafka-server-start.sh -daemon $CLUSTER_DIR/broker2/server.properties
echo "Broker 2 starting..."

sleep 2

# Start Broker 3
echo "Starting Broker 3 (node.id=3)..."
$KAFKA_HOME/bin/kafka-server-start.sh -daemon $CLUSTER_DIR/broker3/server.properties
echo "Broker 3 starting..."

echo ""
echo "All brokers started!"
echo ""
echo "Kafka broker endpoints:"
echo "  - Broker 1: localhost:9092"
echo "  - Broker 2: localhost:9192"
echo "  - Broker 3: localhost:9292"
echo ""
echo "Bootstrap servers: localhost:9092,localhost:9192,localhost:9292"
echo ""
echo "Wait a few seconds for the cluster to form, then check status with:"
echo "  $KAFKA_HOME/bin/kafka-metadata.sh --snapshot $CLUSTER_DIR/broker1/data/__cluster_metadata-0/00000000000000000000.log --command describe"
