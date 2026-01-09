# Z3 - Zcash Protocol Development Stack

Development environment for Zcash protocol changes. Combines Zebra (node), Zaino (indexer), zcash-devtool (wallet/CLI), and local forks of orchard and librustzcash.

**Current Goal:** Add native tag field to Orchard actions for PIR-based transaction detection.

## Quick Start

```bash
# Clone with submodules
git clone --recursive https://github.com/greg-nagy/z3.git
cd z3

# Install overmind (process manager)
brew install overmind  # macOS
# or: go install github.com/DarthSim/overmind/v2@latest

# Build zcash-devtool (one time)
cd zcash-devtool && cargo build --release && cd ..

# Start the stack (Regtest mode)
overmind start
```

Unified, color-coded logs from Zebra and Zaino. Press `Ctrl+C` to stop.

## Verify Setup

```bash
./tests/integration_test.sh
```

This verifies:
- Services running (Zebra mining, Zaino indexing)
- Local patches active (orchard, librustzcash)
- Wallet initialization on Regtest
- Full data flow: Zebra → Zaino → zcash-devtool

## Development Workflow

### Making Protocol Changes

```bash
# 1. Start services
overmind start

# 2. Edit orchard (e.g., add tag field to Action struct)
cd orchard
git checkout -b feature/add-tag-field
# ... edit src/action.rs ...

# 3. Rebuild and test
overmind restart zaino  # Picks up orchard changes
./tests/integration_test.sh

# 4. Commit
git add -A && git commit -m "Add tag field to Action struct"
cd ..
git add orchard && git commit -m "Update orchard with tag field"
```

### Service Commands

```bash
overmind start              # Start all services
overmind restart zaino      # Restart one service
overmind stop               # Stop all
overmind echo zebra         # Follow one service's logs
```

### Manual Execution

```bash
# Terminal 1 - Zebra
cargo run --release -p zebrad --features internal-miner \
  --manifest-path zebra/Cargo.toml -- -c config/zebra-regtest.toml

# Terminal 2 - Zaino
cargo run --release -p zainod \
  --manifest-path zaino/Cargo.toml -- -c config/zaino-regtest.toml
```

## Using zcash-devtool

```bash
DEVTOOL=./zcash-devtool/target/release/zcash-devtool

# Initialize wallet on Regtest
$DEVTOOL wallet -w .wallet init \
  --name test \
  --identity .wallet/id.age \
  --network regtest \
  --server localhost:8137 \
  --mnemonic "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"

# Generate address
$DEVTOOL wallet -w .wallet generate-address

# Sync wallet
$DEVTOOL wallet -w .wallet sync --server localhost:8137

# Check balance
$DEVTOOL wallet -w .wallet balance
```

## Repository Structure

```
z3/
├── zebra/          Full node (submodule)
├── zaino/          Indexer (submodule)  
├── zcash-devtool/  Wallet CLI (submodule)
├── orchard/        Orchard protocol (submodule) ← tag field goes here
├── librustzcash/   Zcash primitives (submodule)
├── config/         Service configs (regtest, docker)
├── scripts/        Setup scripts
├── tests/          Integration tests
├── Procfile        overmind process definitions
└── docker-compose.yml  Docker deployment (CI/staging)
```

## Configuration

| File | Purpose |
|------|---------|
| `config/zebra-regtest.toml` | Zebra: Regtest, internal miner, no auth |
| `config/zaino-regtest.toml` | Zaino: connects to local Zebra |
| `config/*-docker.toml` | Docker deployment variants |

**Default: Regtest mode** - No sync, instant blocks, isolated network.

## Branch Workflow

**Main repo:** `main` is the primary development branch.

**Submodules:** 
- `main` - Z3 development (pinned to compatible versions)
- `feature/*` - Your feature branches
- `pr/*` - For upstream contributions (branch from `upstream/main`)

```bash
# Feature work
cd orchard
git checkout -b feature/my-change
# ... work ...
git commit && git push origin feature/my-change

# Merge when ready
git checkout main && git merge feature/my-change
git push origin main

# Update z3
cd .. && git add orchard && git commit -m "Update orchard"
```

## Version Compatibility

| Component | Version | Constraint |
|-----------|---------|------------|
| zebra | main | - |
| zaino | main | - |
| orchard | 0.11.x | Zebra compatibility |
| librustzcash | zcash_transparent-0.6.3 | Zebra compatibility |
| zcash-devtool | main | - |

Run `./scripts/setup-fork-branches.sh` to verify/reset submodule versions.

## Docker (CI/Deployment)

For automated testing or deployment (not daily dev):

```bash
docker compose build
docker compose up -d
```

Uses `config/*-docker.toml` with container-appropriate paths.

## Prerequisites

- **Rust:** 1.86+ (check zebra/rust-toolchain.toml)
- **overmind:** `brew install overmind`
- **protobuf:** `brew install protobuf` (for gRPC compilation)

## License

MIT OR Apache-2.0
