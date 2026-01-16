# Redpanda 3-Node Cluster Deployment

Configuration and scripts for deploying a 3-node Redpanda cluster on a single machine.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Single Machine                           │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Node 1    │  │    Node 2    │  │    Node 3    │      │
│  │  node_id=0   │  │  node_id=1   │  │  node_id=2   │      │
│  │              │  │              │  │              │      │
│  │ Kafka: 19092 │  │ Kafka: 29092 │  │ Kafka: 39092 │      │
│  │ Admin: 19644 │  │ Admin: 29644 │  │ Admin: 39644 │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                             │
│              Raft-based consensus replication              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

Requires Linux with Redpanda installed.

```bash
# Start cluster
./start-cluster.sh

# Stop cluster
./stop-cluster.sh
```

## Configuration

### Endpoints

| Node | Kafka API | RPC | Admin |
|------|-----------|-----|-------|
| 1    | 127.0.0.1:19092 | 127.0.0.1:33145 | 127.0.0.1:19644 |
| 2    | 127.0.0.1:29092 | 127.0.0.1:33146 | 127.0.0.1:29644 |
| 3    | 127.0.0.1:39092 | 127.0.0.1:33147 | 127.0.0.1:39644 |

Bootstrap servers: `127.0.0.1:19092,127.0.0.1:29092,127.0.0.1:39092`

### Configuration Files

- `redpanda-cluster/node1/redpanda.yaml`
- `redpanda-cluster/node2/redpanda.yaml`
- `redpanda-cluster/node3/redpanda.yaml`

## Directory Structure

```
.
├── README.md
├── start-cluster.sh          # Start Redpanda cluster
├── stop-cluster.sh           # Stop Redpanda cluster
└── redpanda-cluster/
    ├── node1/redpanda.yaml
    ├── node2/redpanda.yaml
    └── node3/redpanda.yaml
```

## Troubleshooting

### Ports already in use

```bash
netstat -tlpn | grep -E "19092|29092|39092"
```
