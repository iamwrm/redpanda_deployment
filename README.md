# Kafka/Redpanda 3-Node Cluster Deployment

This repository contains configurations and scripts for deploying a 3-node streaming data cluster on a single machine.

## Overview

This project includes:
- **Redpanda configurations** (binary-based, requires Linux kernel AIO support)
- **Apache Kafka KRaft cluster** (3 brokers, no Zookeeper required)
- **Python client** using `uv` for producing/consuming messages

## Architecture

### Kafka KRaft 3-Broker Cluster

```
┌─────────────────────────────────────────────────────────────┐
│                    Single Machine                            │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Broker 1   │  │   Broker 2   │  │   Broker 3   │       │
│  │   node.id=1  │  │   node.id=2  │  │   node.id=3  │       │
│  │              │  │              │  │              │       │
│  │ Kafka: 9092  │  │ Kafka: 9192  │  │ Kafka: 9292  │       │
│  │ Ctrl:  9093  │  │ Ctrl:  9094  │  │ Ctrl:  9095  │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
│         KRaft Quorum (Raft-based consensus)                 │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Java 21+ (for Kafka)
- Python 3.11+ with `uv` (for Python client)

### Starting the Kafka Cluster

```bash
# Start all 3 brokers
./start-kafka-cluster.sh

# Wait for cluster to form (about 10 seconds)
sleep 10

# Verify brokers are running
ps aux | grep kafka.Kafka
```

### Stopping the Kafka Cluster

```bash
./stop-kafka-cluster.sh
```

### Running the Python Demo

```bash
cd kafka-python-client
uv run python kafka_demo.py
```

## Configuration

### Kafka Broker Endpoints

| Broker | Kafka API | Controller |
|--------|-----------|------------|
| 1      | localhost:9092 | localhost:9093 |
| 2      | localhost:9192 | localhost:9094 |
| 3      | localhost:9292 | localhost:9095 |

Bootstrap servers: `localhost:9092,localhost:9192,localhost:9292`

### Cluster Configuration

- **Replication Factor**: 3 (data replicated across all brokers)
- **Min In-Sync Replicas**: 2 (for durability)
- **Default Partitions**: 3

### Configuration Files

- `kafka-cluster/broker1/server.properties` - Broker 1 config
- `kafka-cluster/broker2/server.properties` - Broker 2 config
- `kafka-cluster/broker3/server.properties` - Broker 3 config

## Redpanda Notes

The Redpanda binary requires Linux kernel AIO support (`/proc/sys/fs/aio-max-nr`). In containerized environments without this kernel feature, use the Kafka KRaft cluster instead.

Redpanda configuration files are included for reference:
- `redpanda-cluster/node1/redpanda.yaml`
- `redpanda-cluster/node2/redpanda.yaml`
- `redpanda-cluster/node3/redpanda.yaml`

### Redpanda Ports (if running on a full Linux system)

| Node | Kafka API | RPC | Admin |
|------|-----------|-----|-------|
| 1    | 19092     | 33145 | 19644 |
| 2    | 29092     | 33146 | 29644 |
| 3    | 39092     | 33147 | 39644 |

## Python Client

The Python client demonstrates:
- Connecting to the cluster
- Listing cluster metadata and topics
- Producing JSON messages with keys
- Consuming messages from topics
- Consumer group management

### Dependencies

- `kafka-python-ng` - Kafka client library

### Usage

```bash
cd kafka-python-client

# Install dependencies
uv sync

# Run the demo
uv run python kafka_demo.py
```

## Directory Structure

```
.
├── README.md
├── start-kafka-cluster.sh       # Start Kafka cluster
├── stop-kafka-cluster.sh        # Stop Kafka cluster
├── start-cluster.sh             # Start Redpanda cluster (requires AIO)
├── stop-cluster.sh              # Stop Redpanda cluster
├── kafka/                       # Apache Kafka 3.9.1 installation
├── kafka-cluster/               # Kafka broker configurations
│   ├── broker1/
│   ├── broker2/
│   └── broker3/
├── redpanda-cluster/            # Redpanda node configurations
│   ├── node1/
│   ├── node2/
│   └── node3/
└── kafka-python-client/         # Python client project
    ├── pyproject.toml
    └── kafka_demo.py
```

## Troubleshooting

### Kafka brokers not starting
Check if ports are already in use:
```bash
netstat -tlpn | grep -E "909[0-9]|919[0-9]|929[0-9]"
```

### Consumer not receiving messages
Ensure you're using the correct consumer group and offset reset policy:
```python
KafkaConsumer(
    'topic-name',
    auto_offset_reset='earliest',  # or 'latest'
    group_id='your-consumer-group'
)
```

### Redpanda "open: No such file or directory" error
This indicates missing kernel AIO support. Use the Kafka cluster instead, or run on a system with full `/proc/sys/fs` access.

## License

This deployment configuration is provided as-is for educational and development purposes.
