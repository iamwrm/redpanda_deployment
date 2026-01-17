# Redpanda 3-Node Cluster Deployment

Configuration and scripts for deploying and testing a 3-node Redpanda cluster on a single machine.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Single Machine                           │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Node 1    │  │    Node 2    │  │    Node 3    │      │
│  │  node_id=0   │  │  node_id=1   │  │  node_id=2   │      │
│  │  (seed)      │  │              │  │              │      │
│  │              │  │              │  │              │      │
│  │ Kafka: 19092 │  │ Kafka: 29092 │  │ Kafka: 39092 │      │
│  │ Admin: 19644 │  │ Admin: 29644 │  │ Admin: 39644 │      │
│  │ RPC:   33145 │  │ RPC:   33146 │  │ RPC:   33147 │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                             │
│              Raft-based consensus replication              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Linux (amd64 architecture)
- curl
- No pre-installed Redpanda required (scripts auto-download)

### Running the 3-Node Cluster

```bash
# Start cluster
./start-cluster.sh

# Check cluster health
rpk cluster health -X brokers=127.0.0.1:19092

# Stop cluster
./stop-cluster.sh
```

### Running Automated Tests

The `scripts/` directory contains a complete testing toolkit:

```bash
# Run full test suite (downloads, starts, tests, keeps running)
./scripts/test-all.sh

# Or run individual steps:
./scripts/download-redpanda.sh    # Download Redpanda binaries
./scripts/start-redpanda.sh       # Start single-node instance
./scripts/wait-for-health.sh      # Wait for cluster health
./scripts/run-tests.sh            # Run functional tests
./scripts/stop-redpanda.sh        # Stop instance
```

## Configuration

### Endpoints

| Node | Kafka API | RPC | Admin | PandaProxy | Schema Registry |
|------|-----------|-----|-------|------------|-----------------|
| 1 (seed) | 127.0.0.1:19092 | 127.0.0.1:33145 | 127.0.0.1:19644 | - | - |
| 2 | 127.0.0.1:29092 | 127.0.0.1:33146 | 127.0.0.1:29644 | 127.0.0.1:28082 | 127.0.0.1:28081 |
| 3 | 127.0.0.1:39092 | 127.0.0.1:33147 | 127.0.0.1:39644 | 127.0.0.1:38082 | 127.0.0.1:38081 |

Bootstrap servers: `127.0.0.1:19092,127.0.0.1:29092,127.0.0.1:39092`

### Cluster Formation

- **Node 1** is the seed node with `empty_seed_starts_cluster: true`
- **Node 2 & 3** join by pointing `seed_servers` to Node 1's RPC port (33145)
- All nodes run in `developer_mode: true` for relaxed resource requirements

### Configuration Files

- `redpanda-cluster/node1/redpanda.yaml` - Seed node configuration
- `redpanda-cluster/node2/redpanda.yaml` - Secondary node configuration
- `redpanda-cluster/node3/redpanda.yaml` - Tertiary node configuration

## Directory Structure

```
.
├── README.md
├── start-cluster.sh              # Start 3-node Redpanda cluster
├── stop-cluster.sh               # Stop 3-node Redpanda cluster
├── redpanda-cluster/             # Node configuration files
│   ├── node1/redpanda.yaml
│   ├── node2/redpanda.yaml
│   └── node3/redpanda.yaml
├── scripts/                      # Utility scripts
│   ├── test-all.sh               # Master test orchestrator
│   ├── download-redpanda.sh      # Download Redpanda v25.3.1-1
│   ├── start-redpanda.sh         # Start single-node instance
│   ├── stop-redpanda.sh          # Stop instance gracefully
│   ├── wait-for-health.sh        # Poll until cluster healthy
│   └── run-tests.sh              # Functional test suite
└── .github/workflows/
    └── test-cluster.yml          # CI pipeline
```

## Scripts Reference

| Script | Description |
|--------|-------------|
| `start-cluster.sh` | Starts all 3 nodes simultaneously, saves PIDs for shutdown |
| `stop-cluster.sh` | Stops cluster by reading PIDs or force-killing processes |
| `scripts/test-all.sh` | Full orchestration: download → start → health check → test |
| `scripts/download-redpanda.sh` | Downloads and extracts Redpanda from official Debian packages |
| `scripts/start-redpanda.sh` | Starts a single Redpanda node with dynamic config generation |
| `scripts/stop-redpanda.sh` | Graceful shutdown with 30s timeout before force kill |
| `scripts/wait-for-health.sh` | Polls cluster health (max 30 attempts, 2s intervals) |
| `scripts/run-tests.sh` | Tests: create topic, produce/consume messages, describe topic |

## CI/CD

GitHub Actions workflow (`.github/workflows/test-cluster.yml`) runs on:
- Push to any branch
- Pull requests to main/master
- Manual dispatch

The pipeline tests the cluster in a `debian:trixie-slim` container.

## Troubleshooting

### Ports already in use

```bash
# Check for conflicting processes
netstat -tlpn | grep -E "19092|29092|39092|33145|33146|33147"

# Force kill any remaining Redpanda processes
pkill -9 -f redpanda
```

### Check cluster health

```bash
# Using rpk
rpk cluster health -X brokers=127.0.0.1:19092

# Check individual node status
rpk cluster info -X brokers=127.0.0.1:19092
```

### View logs

Redpanda logs are written to stdout by default. Check the terminal where `start-cluster.sh` was run, or redirect output:

```bash
./start-cluster.sh 2>&1 | tee cluster.log
```

### Reset data directories

```bash
# Stop cluster first
./stop-cluster.sh

# Remove data directories
rm -rf /tmp/redpanda-node*/
```

### Common issues

- **Cluster not forming**: Ensure Node 1 starts first and is healthy before other nodes attempt to join
- **Health check timeout**: Developer mode reduces resource requirements but cluster still needs a few seconds to elect leaders
- **Permission denied**: Scripts require execute permission (`chmod +x *.sh scripts/*.sh`)
