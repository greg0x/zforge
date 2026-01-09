# Z3 - Unified Zcash Stack

A development environment for Zcash protocol work combining Zebra (full node), Zaino (indexer), zcash-devtool (wallet/testing), and local forks of orchard and librustzcash.

## Quick Start

```bash
# Clone with submodules
git clone --recursive https://github.com/greg-nagy/z3.git
cd z3

# Install overmind (process manager)
brew install overmind  # macOS
# or: go install github.com/DarthSim/overmind/v2@latest

# Start the stack
overmind start
```

That's it. You'll see unified, color-coded logs from both Zebra and Zaino. Press `Ctrl+C` to stop.

## Development Workflow

```bash
# Start services (first run compiles, subsequent runs are fast)
overmind start

# Restart just one service after code changes
overmind restart zaino

# Stop everything
Ctrl+C  # or: overmind stop
```

### Making Changes

Edit orchard or librustzcash - changes propagate immediately:

```bash
cd orchard
git checkout -b feature/my-change
# ... edit files ...

# Restart to pick up changes (cargo rebuilds automatically)
overmind restart zaino
```

### Running Services Manually

If you prefer separate terminals or need to debug:

```bash
# Terminal 1 - Zebra
cargo run --release -p zebrad --features internal-miner \
  --manifest-path zebra/Cargo.toml -- -c config/zebra-regtest.toml

# Terminal 2 - Zaino (after Zebra starts)
cargo run --release -p zainod \
  --manifest-path zaino/Cargo.toml -- -c config/zaino-regtest.toml
```

## Configuration

- `config/zebra-regtest.toml` - Zebra config (Regtest, internal miner, ephemeral state)
- `config/zaino-regtest.toml` - Zaino config (connects to local Zebra)

**Default: Regtest mode** - No sync needed, instant blocks for protocol development.

## Repository Structure

```
z3/
├── zebra/          Full node (Zebra)
├── zaino/          Indexer (Zaino)
├── zcash-devtool/  Wallet/testing CLI
├── orchard/        Orchard protocol (local fork)
├── librustzcash/   Zcash primitives (local fork)
├── config/         Service configuration files
└── Procfile        Process definitions for overmind
```

**Cargo patches are active** - changes to `orchard/` or `librustzcash/` are picked up by zebra and zaino automatically.

## Committing Your Work

**In submodules:**
```bash
cd orchard  # or zaino, zebra, librustzcash
git checkout -b feature/your-change
git add <files>
git commit -m "Add feature"
git push origin feature/your-change
```

**In main z3 repo (to update submodule pointers):**
```bash
git add orchard  # whichever submodule changed
git commit -m "Update orchard with feature X"
```

## Version Info

| Component | Version | Notes |
|-----------|---------|-------|
| zebra | v3.1.0 | Current |
| zaino | v0.1.2-rc3 | Current |
| orchard | v0.11.0 | Pinned for zebra compatibility |
| librustzcash | @ zcash_transparent-0.6.3 | Pinned for zebra compatibility |

## Prerequisites

- **Rust:** Latest stable toolchain
- **overmind:** `brew install overmind` (or foreman: `gem install foreman`)

## Setup Remotes (Optional)

Run `./scripts/setup-dev-env.sh` to add upstream remotes for syncing with official repos.

## License

MIT OR Apache-2.0
