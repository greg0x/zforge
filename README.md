# Z3 - Unified Zcash Stack

A development environment for Zcash protocol work combining Zebra (full node), Zaino (indexer), and local forks of orchard and librustzcash.

## Quick Start for Developers

```bash
# 1. Clone with submodules
git clone --recursive https://github.com/greg-nagy/z3.git
cd z3

# 2. Verify compilation
cd zebra && cargo check --workspace && cd ..
cd zaino && cargo check --workspace && cd ..
# ✅ Both should succeed
```

**Optional:** Run `./scripts/setup-dev-env.sh` to add upstream remotes for syncing with official repos.

**What you get:**
- Submodules at correct commits (orchard v0.11.0, librustzcash @ zcash_transparent-0.6.3)
- Local patches active - changes to `orchard/` or `librustzcash/` propagate immediately
- Ready to build and develop

## Version Info

| Component | Version | Latest | Why Pinned |
|-----------|---------|--------|------------|
| zebra | v3.1.0 | v3.1.0 | ✅ Current |
| zaino | v0.1.2-rc3 | v0.1.2-rc3 | ✅ Current |
| orchard | v0.11.0 | v0.12.0 | zebra compatibility |
| librustzcash | @ zcash_transparent-0.6.3 | Newer | zebra compatibility |

**Why these versions?** Zebra v3.1.0 requires orchard v0.11.0 (v0.12.0 has breaking changes) and zcash_transparent v0.6.3.

**Cargo patches active in zebra/Cargo.toml and zaino/Cargo.toml:**
```toml
[patch.crates-io]
orchard = { path = "../orchard" }
zcash_primitives = { path = "../librustzcash/zcash_primitives" }
# ... all zcash_* crates patched to local versions
```

## Making Changes

Edit orchard or librustzcash - changes are immediately available (no crates.io publish needed):

```bash
cd orchard
git checkout -b feature/my-change
# ... edit files ...
git commit -m "Add feature"
git push origin feature/my-change

# Test immediately
cd ../zebra && cargo check  # ✅ Uses ../orchard
cd ../zaino && cargo check  # ✅ Uses ../orchard
```

## Committing Your Work

**In submodules:**
```bash
cd zebra  # or zaino, orchard, librustzcash
git checkout -b feature/your-change
git add <files>
git commit  # See .cursorrules for commit message guidelines
git push origin feature/your-change
```

**In main z3 repo (to update submodule pointers):**
```bash
git add zebra  # or whichever submodule changed
git commit -m "Update zebra with feature X"
git push origin dev
```

See `.cursor/rules/` for detailed commit and submodule guidelines.

## Running the Stack (Docker)

> [!NOTE]
> **Mac Silicon Users:** Set `DOCKER_PLATFORM=linux/arm64` in `.env` for native builds (3 min vs 50 min compile time).

```bash
# Start development environment (generates TLS certs if needed)
./scripts/dev-start.sh

# Stop development environment
./scripts/dev-stop.sh

# Restart after code changes
./scripts/dev-restart.sh zaino  # Rebuild zaino after orchard/librustzcash changes
```

**Default: Regtest mode** (no sync needed, instant blocks). See [docs/docker-deployment.md](docs/docker-deployment.md) for production deployment guide.

## Repository Structure

```
z3/
├── zebra/           Full node (greg-nagy/zebra → ZcashFoundation/zebra)
├── zaino/           Indexer (greg-nagy/zaino → zingolabs/zaino)
├── orchard/         Orchard protocol (greg-nagy/orchard → zcash/orchard)
├── librustzcash/    Zcash primitives (greg-nagy/librustzcash → zcash/librustzcash)
└── zcashd/          Legacy reference (greg-nagy/zcashd → zcash/zcash)
```

Each submodule has:
- `origin` → your fork (push here)
- `upstream` → official repo (sync from here)

## Prerequisites

- **Rust:** Latest stable toolchain
- **Docker & Docker Compose:** For running the stack
- **Git:** For submodules

## Notes

- **Zallet removed:** Incompatible versions (requires zcash_primitives v0.19, we use v0.26)
- **For wallet testing:** Use integration tests or zcash-devtool
- **Sync time:** Testnet 2-12 hours, Mainnet 24-72 hours
- **Non-Mac Silicon Users:** Comment out `DOCKER_PLATFORM=linux/arm64` in `.env` .

## Documentation

- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Full Docker deployment guide
- **[scripts/setup-dev-env.sh](scripts/setup-dev-env.sh)** - Submodule setup script

## License

MIT OR Apache-2.0
