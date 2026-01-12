# Zforge - Zcash Protocol Development Stack

Development environment for Zcash protocol changes. Combines Zebra (node), Zaino (indexer), zcash-devtool (wallet/CLI), and local forks of orchard and librustzcash.

**Current Goal:** Add native tag field to Orchard actions for PIR-based transaction detection.

## Getting Started

### New Contributor (Recommended)

Create your own forks of all repositories so you can push changes:

```bash
# 1. Clone the template repo
git clone --recursive https://github.com/greg-nagy/zforge.git
cd zforge

# 2. Fork all repos to your GitHub account (requires gh CLI)
./dev fork

# 3. Initialize submodules with your forks
./dev setup

# 4. Build and run
./dev build
./dev up
./dev test
```

The `./dev fork` command will:

- Fork zforge and all 5 submodules to your GitHub account
- Configure `origin` → your fork, `upstream` → official repos
- Update `.gitmodules` to use your forks

### Quick Start (Read-Only)

If you just want to explore without pushing changes:

```bash
git clone --recursive https://github.com/greg-nagy/zforge.git
cd zforge
./dev setup && ./dev build && ./dev up
```

## Development Commands

```bash
# Onboarding
./dev fork      # Fork all repos to your GitHub account
./dev setup     # Initialize submodules, configure remotes

# Services
./dev up        # Start all services (zebra + zaino)
./dev stop      # Stop all services
./dev restart   # Restart services
./dev status    # Show service status
./dev logs      # Follow all logs
./dev logs zaino  # Follow specific service

# Development
./dev build     # Build zcash-devtool
./dev test      # Run integration tests

# Git (multi-repo)
./dev git status          # Status across all repos
./dev git branch <name>   # Create feature branch
./dev git commit <msg>    # Commit across submodules
./dev git push            # Push all repos (to your forks)
./dev git sync            # Fetch upstream, show drift
```

## Running with NU7 (Experimental)

NU7 features (including the tag field for Orchard actions) require special build flags:

```bash
# Start the full stack with NU7 support (recommended)
./dev up --nu7

# Or build individual components with NU7:
./dev build --nu7              # Build zcash-devtool with NU7

# Manual builds:
export RUSTFLAGS='--cfg zcash_unstable="nu7"'
cargo build --release -p zebrad --features internal-miner
cargo build --release -p zainod
cargo build --release -p zcash-devtool
```

The `--nu7` flag sets `RUSTFLAGS='--cfg zcash_unstable="nu7"'` which enables:

- V6 transaction format with 16-byte tag field in Orchard actions
- PIR-based transaction detection for mobile wallets
- Reduced bandwidth/battery usage via server-side filtering

The regtest configuration already has NU7 activated at block 1.

## What the Tests Verify

- Services running (Zebra mining, Zaino indexing)
- Local patches active (orchard, librustzcash)
- Wallet initialization on Regtest
- Full data flow: Zebra → Zaino → zcash-devtool

## Development Workflow

### Making Protocol Changes

```bash
# 1. Start feature branch
./dev git branch add-tag-field    # Creates feature/add-tag-field in orchard + librustzcash

# 2. Start services
./dev up

# 3. Make changes
cd orchard
# ... edit src/action.rs ...

# 4. Rebuild and test
./dev restart                     # Picks up orchard changes
./dev test

# 5. Commit and push
./dev git commit "Add tag field to Action struct"
./dev git push
```

### Service Commands

```bash
# Via ./dev (recommended)
./dev up                    # Start all services
./dev restart               # Restart all
./dev stop                  # Stop all
./dev logs zaino            # Follow one service's logs

# Direct overmind (if needed)
overmind restart zaino      # Restart specific service
overmind echo zebra         # Follow specific service
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
zforge/
├── dev                 # CLI entry point (./dev setup, ./dev up, etc.)
├── mise.toml           # Tool versions (protobuf)
├── Procfile            # overmind process definitions
├── zebra/              # Full node (submodule)
├── zaino/              # Indexer (submodule)
├── zcash-devtool/      # Wallet CLI (submodule)
├── orchard/            # Orchard protocol (submodule) ← tag field goes here
├── librustzcash/       # Zcash primitives (submodule)
├── config/             # Service configs (regtest, docker)
├── scripts/            # Setup scripts
├── tests/              # Integration tests
├── docs/               # Planning docs
└── docker-compose.yml  # Docker deployment (CI/staging)
```

## Configuration

| File                        | Purpose                                 |
| --------------------------- | --------------------------------------- |
| `config/zebra-regtest.toml` | Zebra: Regtest, internal miner, no auth |
| `config/zaino-regtest.toml` | Zaino: connects to local Zebra          |
| `config/*-docker.toml`      | Docker deployment variants              |

**Default: Regtest mode** - No sync, instant blocks, isolated network.

## Fork & Remote Structure

After running `./dev fork`, each repo has two remotes:

| Remote     | Points To     | Purpose                |
| ---------- | ------------- | ---------------------- |
| `origin`   | Your fork     | Push your changes here |
| `upstream` | Official repo | Sync upstream changes  |

**Submodule upstreams:**

- `zebra` → ZcashFoundation/zebra
- `zaino` → zingolabs/zaino
- `orchard` → zcash/orchard
- `librustzcash` → zcash/librustzcash
- `zcash-devtool` → zcash/zcash-devtool

## Branch Workflow

**Branches:**

- `main` / `dev` - Zforge development (pinned to compatible versions)
- `feature/*` - Your feature branches
- `pr/*` - For upstream contributions (branch from `upstream/main`)

```bash
# Start feature (creates branch in orchard + librustzcash by default)
./dev git branch my-feature

# Or specify repos
./dev git branch my-feature orchard zebra zaino

# Work, then commit across all dirty repos
./dev git commit "My changes"

# Push everything (goes to your forks)
./dev git push

# Check upstream drift
./dev git sync
```

## Version Compatibility

| Component     | Version                 | Constraint          |
| ------------- | ----------------------- | ------------------- |
| zebra         | main                    | -                   |
| zaino         | main                    | -                   |
| orchard       | 0.11.x                  | Zebra compatibility |
| librustzcash  | zcash_transparent-0.6.3 | Zebra compatibility |
| zcash-devtool | main                    | -                   |

Run `./scripts/setup-fork-branches.sh` to verify/reset submodule versions.

## Docker (CI/Deployment)

For automated testing or deployment (not daily dev):

```bash
docker compose build
docker compose up -d
```

Uses `config/*-docker.toml` with container-appropriate paths.

## Prerequisites

Run `./dev setup` to check all prerequisites.

**Required:**

- **Rust:** Managed per-submodule via `rust-toolchain.toml` (rustup handles automatically)
- **tmux:** `brew install tmux` (required by overmind)
- **overmind:** `brew install overmind` (process manager)
- **protobuf:** `brew install protobuf` (for gRPC compilation)

**Required for `./dev fork`:**

- **gh:** `brew install gh` (GitHub CLI for forking repos)
- Run `gh auth login` to authenticate

**Optional:**

- **mise:** `https://mise.jdx.dev` (manages tool versions via `mise.toml`)

## License

MIT OR Apache-2.0
