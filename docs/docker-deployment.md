# Docker Deployment Guide

Complete guide for deploying the Z3 stack with Docker Compose.

## Table of Contents

- [Prerequisites](#prerequisites)
- [System Requirements](#system-requirements)
- [First Time Setup](#first-time-setup)
- [Configuration](#configuration)
- [Health Checks](#health-checks)
- [Data Storage](#data-storage)

## Prerequisites

- **Docker Engine** and **Docker Compose**
- **OpenSSL** for generating TLS certificates
- **Git** for cloning repositories

## System Requirements

### Minimum
- CPU: 2 cores (4+ recommended)
- RAM: 4 GB for Zebra; 8+ GB for full stack
- Disk: Mainnet 300 GB, Testnet 30 GB (SSD recommended)
- Network: Reliable internet, ~300 GB initial sync

### Recommended
- CPU: 4+ cores
- RAM: 16+ GB
- Disk: 500+ GB SSD
- Network: 100+ Mbps with ~300 GB/month bandwidth

### Sync Times
- Mainnet: 24-72 hours
- Testnet: 2-12 hours

## First Time Setup

### 1. Clone and Initialize

```bash
git clone https://github.com/ZcashFoundation/z3
cd z3
git submodule update --init --recursive
```

### 2. Platform Configuration (Mac Silicon)

**ARM64 users (Apple Silicon M1/M2/M3):**

Edit `.env` and set:
```bash
DOCKER_PLATFORM=linux/arm64
```

This reduces build time from ~50 minutes to ~3 minutes.

**Intel/AMD users:** Default settings work optimally.

### 3. Generate Required Files

**TLS Certificates for Zaino:**
```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout config/tls/zaino.key \
  -out config/tls/zaino.crt \
  -sha256 -days 365 -nodes \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,DNS:zaino,IP:127.0.0.1"
```

### 4. Build Services

```bash
docker compose build zaino
```

Note: Zebra uses pre-built image `zfnd/zebra:3.1.0`

### 5. Start Services

**First time (fresh sync):**
```bash
# Start only Zebra first
docker compose up -d zebra

# Wait for sync (hours to days)
./check-zebra-readiness.sh

# Once synced, start everything
docker compose up -d
```

**Returning user (existing data):**
```bash
docker compose up -d
```

## Configuration

### Environment Variables

Key variables in `.env`:

```bash
# Network (Mainnet or Testnet)
NETWORK_NAME=Testnet

# Ports
Z3_ZEBRA_HOST_RPC_PORT=18232
ZAINO_HOST_GRPC_PORT=8137

# Log levels
Z3_ZEBRA_RUST_LOG=info
ZAINO_RUST_LOG=info,reqwest=warn,hyper_util=warn
```

### Configuration Hierarchy

Variables are applied in order (later overrides earlier):
1. Dockerfile defaults
2. `.env` file
3. `environment` section in docker-compose.yml
4. Shell environment variables

### Common Customizations

**Change network:**
```bash
NETWORK_NAME=Mainnet  # or Testnet
```

**Adjust log levels:**
```bash
Z3_ZEBRA_RUST_LOG=debug
ZAINO_RUST_LOG=debug
```

**Change ports:**
```bash
Z3_ZEBRA_HOST_RPC_PORT=18232
ZAINO_HOST_GRPC_PORT=8137
```

## Health Checks

### Zebra Endpoints

**`/healthy` - Liveness Check**
- Returns 200: Zebra running with minimum peers
- Returns 503: Not enough peer connections
- Use for: Docker healthchecks, restart decisions
- Works during: Initial sync, normal operation

**`/ready` - Readiness Check**
- Returns 200: Synced near network tip (within 2 blocks)
- Returns 503: Still syncing
- Use for: Production traffic routing
- Fails during: Fresh sync (24+ hours for mainnet)

**Endpoints:**
```bash
curl http://localhost:8080/healthy
curl http://localhost:8080/ready
```

### Service Dependencies

```
Zebra (/ready - synced)
  → Zaino (gRPC responding)
```

Why this approach:
- Zaino requires Zebra near network tip
- Two-phase deployment separates sync from operation
- Docker healthcheck verifies Zebra ready before starting Zaino

### Monitoring Sync

```bash
# Check readiness
curl http://localhost:8080/ready

# Watch logs
docker compose logs -f zebra

# Check status
docker compose ps zebra
```

### Health Check Configuration

In `.env`:
```bash
# Blocks behind network tip acceptable (default: 2)
ZEBRA_HEALTH__READY_MAX_BLOCKS_BEHIND=2

# Minimum peers for /healthy (default: 1)
ZEBRA_HEALTH__MIN_CONNECTED_PEERS=1
```

## Data Storage

### Default: Docker Volumes (Recommended)

Named volumes managed by Docker:
- `zebra_data` - Blockchain state (~300GB mainnet, ~30GB testnet)
- `zaino_data` - Indexer database
- `shared_cookie_volume` - RPC authentication

Advantages:
- No permission issues
- Automatic management
- Better performance on macOS/Windows

### Advanced: Local Directories

For backups, external SSDs, or shared storage:

**1. Create directories:**
```bash
mkdir -p /your/path/zebra-state
mkdir -p /your/path/zaino-data
```

**2. Fix permissions:**
```bash
./fix-permissions.sh zebra /your/path/zebra-state
./fix-permissions.sh zaino /your/path/zaino-data
```

**3. Update `.env`:**
```bash
Z3_ZEBRA_DATA_PATH=/your/path/zebra-state
Z3_ZAINO_DATA_PATH=/your/path/zaino-data
```

**4. Restart:**
```bash
docker compose down
docker compose up -d
```

### Security Requirements

Each service runs as specific non-root user:
- **Zebra**: UID=10001, GID=10001, permissions 700
- **Zaino**: UID=1000, GID=1000, permissions 700

**Critical:** Directories must have correct ownership (use `fix-permissions.sh`) and secure permissions (700 or 750, never 755/777).

## Stopping the Stack

```bash
# Stop containers
docker compose down

# Stop and remove data (⚠️ deletes blockchain!)
docker compose down -v
```

## Accessing Services

Once running:
- **Zebra RPC:** `http://localhost:18232` (testnet)
- **Zebra Health:** `http://localhost:8080/healthy` and `/ready`
- **Zaino gRPC:** `localhost:8137`

## Development Mode

To start services during sync (not for production):

```bash
cp docker-compose.override.yml.example docker-compose.override.yml
docker compose up -d
```

This uses `/healthy` instead of `/ready`, allowing services to start immediately.
