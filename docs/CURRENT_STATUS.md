# Z3 Current Status

**Last Updated:** January 9, 2026

## What's Working

### ✅ Production Docker Stack
- Full `docker-compose.yml` with zebra, zaino, zallet services
- Health checks, volume management, networking configured
- ARM64 support for Apple Silicon
- TLS/cookie authentication between services
- **Status:** Production-ready, actively maintained

### ✅ Component Integration
- **Zebra:** Full node (v3.1.0) - syncing and validating blockchain
- **Zaino:** Indexer service - serving gRPC for light clients
- **Zallet:** CLI wallet - embedded indexer, direct Zebra connection
- **Status:** All components operational

### ✅ Documentation
- Comprehensive README with setup instructions
- RPC method mappings documented in `docs/data/`
- Ecosystem tracking scripts
- **Status:** Up-to-date

---

## Current Focus

### 🚧 Tag-Based PIR Prototype (Active Work)

**Goal:** Add 16-byte detection tags to Orchard actions for efficient light client sync

**Timeline:** 4-6 weeks (backend prototype, desktop-only)

**Progress:**
- ✅ Planning complete
- ✅ External dependencies cloned (`externals/orchard`, `externals/librustzcash`)
- ✅ Implementation plan documented (`notes/tag_based_pir_implementation_plan.md`)
- ⏳ **Next:** Phase 1 - Modify `orchard::Action` struct

**Phases:**
1. **Week 1-2:** Protocol layer (orchard + librustzcash)
2. **Week 2-3:** Node layer (Zebra parsing/serving)
3. **Week 3-4:** Indexer layer (Zaino protobuf/extraction)
4. **Week 4-5:** Wallet layer (tag generation/filtering)
5. **Week 5-6:** E2E testing and benchmarking

**Expected Outcome:** 100x+ faster wallet sync via tag-based filtering

---

## Repository Structure

```
z3/
├── zebra/          # Full node (submodule)
├── zaino/          # Indexer (submodule)
├── zallet/         # Wallet (submodule)
├── externals/      # Forked dependencies for tag-PIR work
│   ├── orchard/
│   ├── librustzcash/
│   └── [iOS repos for future mobile work]
├── config/         # Service configurations
├── docs/
│   ├── data/       # RPC mappings, ecosystem info
│   └── archive/    # Historical documentation
├── notes/          # Private working notes (gitignored)
└── docker-compose.yml
```

---

## Known Issues

None currently blocking development.

---

## Next Steps

### Immediate (This Week)
1. Modify `externals/orchard/src/action.rs` - add `tag: [u8; 16]` field
2. Update orchard serialization logic
3. Run orchard test suite

### Short Term (Next 2 Weeks)
1. Update `librustzcash` to propagate tag changes
2. Add Cargo patches to z3 components
3. Begin Zebra integration

### Medium Term (4-6 Weeks)
1. Complete backend tag-PIR implementation
2. E2E testing with zallet
3. Performance benchmarking
4. Decide on mobile integration timeline

---

## Reference Documentation

- **Setup Guide:** [README.md](../README.md)
- **RPC Mappings:** [docs/data/rpc_mapping.md](data/rpc_mapping.md)
- **Tag-PIR Plan:** `notes/tag_based_pir_implementation_plan.md` (private)
- **Quick Start:** `notes/TAG_PIR_QUICKSTART.md` (private)

---

## Historical Context

Previous work focused on Docker orchestration and component integration (completed May 2024). Documentation from that period is archived in `docs/archive/memory-bank-2024-05/`.

Current work (January 2026) focuses on protocol-level enhancements (tag-based PIR) to improve light client performance.
