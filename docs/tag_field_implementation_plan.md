# Tag Field Implementation Plan

> Protocol change to add 16-byte unencrypted detection tags to Orchard actions.
> **Requires NU7 network upgrade and V6 transaction format.**

## Current Status (2026-01-13)

🎉 **V6 transactions with tags are working end-to-end!**

Successfully completed:

- V6 shielding transaction created and mined on regtest
- Tag bytes present in transaction serialization
- Wallet can send/receive Orchard notes via V6 transactions

### Immediate Next Steps

1. **Update Zebra RPC** - `getrawtransaction` doesn't expose `tag` field in JSON (see Phase 6)
2. **Test tag-keys commands** - `show`, `export`, `generate`, `verify`
3. **Test scan-tags** - PIR-based scanning with tag pre-filtering
4. **Clean up debug code** - Remove debug println! statements from shield.rs

### DX Improvements (Nice to Have)

- **Eliminate 100-block coinbase wait** - Currently must wait ~105 blocks before mining rewards are spendable. Options:
  - Faucet approach: separate miner wallet sends regular (non-coinbase) ZEC to test wallet
  - Pre-mine script: generate 110+ blocks before starting tests
  - Track coinbase in wallet DB: apply maturity only to actual coinbase UTXOs, not all transparent

### Issues Fixed During Integration

| Issue                           | Root Cause                                                                         | Fix                                                            |
| ------------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `ScriptInvalid` on V6 tx        | `zip-233` feature enabled in zcash-devtool but not Zebra, causing sighash mismatch | Enabled `zip-233` in `zebra-chain/Cargo.toml`                  |
| `immature coinbase spend`       | Wallet selecting UTXOs too close to chain tip                                      | Increased confirmations from 100→105 in shield.rs              |
| Stale wallet state              | Wallet DB persists across chain restarts                                           | Added `./dev reset-wallet` command, auto-reset on `./dev up`   |
| Transparent input size mismatch | P2PKH calculated as 149 bytes vs ZIP-317 standard 150                              | Fixed `serialized_len()` in `zcash_transparent/src/builder.rs` |

---

## Overview

| Component           | Repository       | Key Files                           | Status        |
| ------------------- | ---------------- | ----------------------------------- | ------------- |
| Protocol layer      | `orchard/`       | `src/action.rs`, `src/tag.rs`       | ✅ Done       |
| Transaction builder | `librustzcash/`  | `zcash_primitives/src/transaction/` | ✅ Done       |
| Node parsing        | `zebra/`         | `zebra-chain/src/orchard/`          | ✅ Done       |
| Indexing            | `zaino/`         | `zaino-state/src/`                  | ✅ Done       |
| Wallet CLI          | `zcash-devtool/` | `src/commands/wallet/shield.rs`     | ✅ V6 Working |
| RPC tag exposure    | `zebra/`         | `zebra-rpc/src/methods/types/`      | 🔶 TODO       |

## Critical Requirement: NU7 Gating

**All tag-related code must be gated behind NU7/V6 feature flags.**

```rust
// In librustzcash/Zebra:
#[cfg(zcash_unstable = "nu7")]           // Network upgrade gate
#[cfg(feature = "tx_v6")]                 // Transaction version gate

// Combined (recommended):
#[cfg(all(zcash_unstable = "nu7", feature = "tx_v6"))]
```

**Why**: Tags change the serialization format. V5 transactions (NU5/NU6) must remain byte-for-byte identical to preserve consensus.

---

## Already Completed

### orchard crate (8 commits on feature/tag-field)

| File                        | Change                                           |
| --------------------------- | ------------------------------------------------ |
| `src/tag.rs`                | New TaggingKey for HMAC-based tag generation     |
| `src/action.rs`             | Added `tag: [u8; 16]` field to Action struct     |
| `src/builder.rs`            | `add_output_with_tag()`, random tags for dummies |
| `src/note_encryption.rs`    | CompactAction with optional tag field            |
| `src/bundle/commitments.rs` | Tag NOT included in txid hash (ZIP-244 compat)   |

### librustzcash (7 commits on feature/tag-field)

| File                                   | Change                                         |
| -------------------------------------- | ---------------------------------------------- |
| `zcash_primitives/.../orchard.rs`      | `read/write_action_without_auth_v6` (gated)    |
| `zcash_primitives/.../orchard.rs`      | `read/write_v6_bundle` now use V6 action funcs |
| `zcash_client_backend/src/proto.rs`    | CompactOrchardAction ↔ CompactAction with tag  |
| `zcash_client_backend/src/scanning.rs` | `matches_tag()` for PIR pre-filtering          |
| `compact_formats.proto`                | Added `bytes tag = 5` to CompactOrchardAction  |

---

## Phase 1: Fix librustzcash V6 Bundle Functions ✅

**Status**: Complete

**File:** `zcash_primitives/src/transaction/components/orchard.rs`

### What was fixed

`read_v6_bundle` and `write_v6_bundle` were stubs calling V5 versions.
Now they properly use the V6 action functions that include the 16-byte tag:

```rust
// read_v6_bundle now uses:
Vector::read(&mut reader, |r| read_action_without_auth_v6(r))

// write_v6_bundle now uses:
Vector::write_nonempty(&mut writer, bundle.actions(), |w, a| {
    write_action_without_auth_v6(w, a)
})
```

**Completed:**

- [x] Update `read_v6_bundle` to use `read_action_without_auth_v6`
- [x] Update `write_v6_bundle` to use `write_action_without_auth_v6`
- [x] Verify V5 builds without NU7 flags

---

## Phase 2: Zebra Implementation ✅

**Status**: Complete

### What was implemented

| File                                       | Change                                                              |
| ------------------------------------------ | ------------------------------------------------------------------- |
| `zebra-chain/src/orchard/action.rs`        | Added `tag: [u8; 16]` field (gated with cfg)                        |
| `zebra-chain/src/orchard/action.rs`        | Added `zcash_serialize_v5/v6` and `zcash_deserialize_v5/v6` methods |
| `zebra-chain/src/transaction/serialize.rs` | `ShieldedData::zcash_serialize_v5/v6` methods                       |
| `zebra-chain/src/transaction/serialize.rs` | V6 transaction uses V6 orchard serialization                        |

**Completed:**

- [x] Add `tag: [u8; 16]` field to Action (gated with cfg)
- [x] Implement `zcash_serialize_v5` / `zcash_deserialize_v5`
- [x] Implement `zcash_serialize_v6` / `zcash_deserialize_v6` (gated)
- [x] Update Transaction serialization to call version-specific methods
- [x] Update Transaction deserialization similarly
- [x] V5 compatibility verified (builds without NU7 flags)
- [x] Add `action_v5_roundtrip` test (verifies 820-byte size, backward compat)
- [x] Add `action_v6_roundtrip` test (verifies 836-byte size, tag preserved)
- [x] Add `v6_strategy` to Transaction::Arbitrary (gated)
- [x] Add `action_with_tag_strategy()` for V6 tag testing

### Tests Added

| Test                  | File                    | Purpose                                        |
| --------------------- | ----------------------- | ---------------------------------------------- |
| `action_v5_roundtrip` | `orchard/tests/prop.rs` | V5 serialization = 820 bytes, roundtrip works  |
| `action_v6_roundtrip` | `orchard/tests/prop.rs` | V6 serialization = 836 bytes, tag is preserved |

Run tests with:

```bash
# V5 test (always runs)
cargo test -p zebra-chain action_v5_roundtrip

# V6 + transaction roundtrip tests (requires NU7 flags)
RUSTFLAGS='--cfg zcash_unstable="nu7"' cargo test -p zebra-chain --features tx_v6 action_v6_roundtrip
RUSTFLAGS='--cfg zcash_unstable="nu7"' cargo test -p zebra-chain --features tx_v6 transaction_roundtrip
```

---

## Phase 3: Zaino Implementation ✅

**Status**: Complete

**Key Principle**: Parse based on transaction version.

### What was implemented

| File                                    | Change                                                    |
| --------------------------------------- | --------------------------------------------------------- |
| `zaino-proto/.../compact_formats.proto` | Added `bytes tag = 5` to CompactOrchardAction             |
| `zaino-fetch/src/chain/transaction.rs`  | Action struct with tag field, V6 parsing, version routing |
| `zaino-state/.../db/legacy.rs`          | CompactOrchardAction with tag, V2 serialization format    |
| `zaino-state/.../helpers.rs`            | cfg-gated tag extraction from zebra-chain actions         |
| `zaino-state/.../db/v1.rs`              | Variable-length action skip for DB cursor operations      |

**Completed:**

- [x] Pass transaction version through parsing chain
- [x] Only read tag bytes for V6 transactions
- [x] Update CompactOrchardAction to include tag (proto + Rust)
- [x] Add V6 transaction parser with version group ID 0xFFFFFFFF
- [x] DB serialization V2 format with backward-compatible V1 decoding
- [x] Tests for V5 compatibility and V6 tag round-trip

---

## Phase 4: NU7 Regtest Activation ✅

**Status**: Complete

### Quick Start

```bash
# Start the full stack with NU7 support
./dev up --nu7

# Mining begins immediately, NU7 activates at block 5
```

### Regtest Configuration

In `config/zebra-regtest.toml`:

```toml
# Canopy at height 1 (required for internal miner)
# Earlier upgrades use regtest defaults (all at genesis)
[network.testnet_parameters.activation_heights]
Canopy = 1
NU5 = 2
NU6 = 3
"NU6.1" = 4
NU7 = 5
```

### Zebra Fixes for NU7

Two fixes were required to enable NU7 mining:

| File                                            | Issue                                    | Fix                                                                                    |
| ----------------------------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------- |
| `zebra-chain/src/parameters/network_upgrade.rs` | NU7 branch ID only enabled for tests     | Changed `#[cfg(any(test, feature = "zebra-test"))]` → `#[cfg(zcash_unstable = "nu7")]` |
| `zebra-network/src/constants.rs`                | Protocol version 170_140 too low for NU7 | Added conditional `170_150` when built with NU7 flag                                   |

### librustzcash LocalNetwork Example

```rust
let regtest = LocalNetwork {
    overwinter: Some(BlockHeight::from_u32(1)),
    sapling: Some(BlockHeight::from_u32(1)),
    blossom: Some(BlockHeight::from_u32(1)),
    heartwood: Some(BlockHeight::from_u32(1)),
    canopy: Some(BlockHeight::from_u32(1)),
    nu5: Some(BlockHeight::from_u32(1)),
    nu6: Some(BlockHeight::from_u32(1)),
    nu6_1: Some(BlockHeight::from_u32(1)),
    #[cfg(zcash_unstable = "nu7")]
    nu7: Some(BlockHeight::from_u32(1)),
};
```

### Manual Build

```bash
# Set the flag for all components
export RUSTFLAGS='--cfg zcash_unstable="nu7"'

# Build individually
cargo build --release -p zebrad --features internal-miner
cargo build --release -p zainod
cargo build --release -p zcash-devtool
```

**Completed:**

- [x] Add `./dev up --nu7` and `./dev restart --nu7` commands
- [x] Configure Zebra regtest for NU7 activation at height 5
- [x] Fix Zebra NU7 branch ID (0xffffffff) to be available in NU7 builds
- [x] Fix Zebra protocol version (170_150) for NU7 builds
- [x] Document LocalNetwork NU7 configuration in librustzcash
- [x] Document NU7 build process in README
- [x] Verify mining works continuously past NU7 activation

---

## Phase 5: Wallet CLI (zcash-devtool) ✅

**Status**: V6 transactions working, tag-keys commands need testing

### What was implemented

| File                               | Change                                             |
| ---------------------------------- | -------------------------------------------------- |
| `src/commands/wallet/tag_keys.rs`  | TaggingKey derivation from Orchard FVK via BLAKE2b |
| `src/commands/wallet/tag_keys.rs`  | `show`, `export`, `generate`, `verify` subcommands |
| `src/commands/wallet/scan_tags.rs` | PIR-based scan with tag pre-filtering              |
| `src/commands/wallet.rs`           | Added `TagKeys` and `ScanTags` to Command enum     |
| `src/main.rs`                      | Wired up new commands                              |

### Commands

```bash
# Display tagging key for an account
zcash-devtool wallet tag-keys show [--account-id UUID]

# Export tagging key in various formats
zcash-devtool wallet tag-keys export [--account-id UUID] [--format hex|base64|json]

# Generate detection tags for specific indices
zcash-devtool wallet tag-keys generate [--account-id UUID] --start 0 --count 100

# Verify a tag matches an index
zcash-devtool wallet tag-keys verify [--account-id UUID] --tag <hex> --index <n>

# Scan blockchain with PIR tag pre-filtering
zcash-devtool wallet scan-tags [--account-id UUID] --start-height 1 --tag-window 1000
```

### Tag Key Derivation

The tagging key is derived deterministically from the Orchard FVK:

```rust
let key = BLAKE2b(personalization: "Zcash_TagKeyDerv", input: fvk_bytes)
let tagging_key = TaggingKey::from_bytes(key[0..32])
```

**Completed:**

- [x] Tag key derivation from FVK (BLAKE2b with personalization)
- [x] `tag-keys show` - display tag key information
- [x] `tag-keys export` - export in hex/base64/json formats
- [x] `tag-keys generate` - generate tags for index range
- [x] `tag-keys verify` - verify tag matches index
- [x] `scan-tags` command using PIR pre-filtering
- [x] Transaction sending with tags (handled by orchard builder automatically)

### Testing Required

```bash
# 1. Start NU7 regtest (resets wallet automatically)
./dev up

# 2. Init wallet
./zcash-devtool/target/release/zcash-devtool wallet init \
  --name test --identity test-id.age --network regtest \
  -s localhost:8137 --mnemonic "abandon ... art"

# 3. Sync and check balance (wait for ~115 blocks for coinbase maturity)
./zcash-devtool/target/release/zcash-devtool wallet sync -s localhost:8137
./zcash-devtool/target/release/zcash-devtool wallet balance

# 4. Shield funds (creates V6 transaction with tags)
./zcash-devtool/target/release/zcash-devtool wallet shield \
  -i test-id.age -s localhost:8137 --disable-tor --target-note-count 1

# 5. Verify tag-keys commands
./zcash-devtool/target/release/zcash-devtool wallet tag-keys show
./zcash-devtool/target/release/zcash-devtool wallet tag-keys generate --count 5
```

### V6 Transaction Verified ✅

```bash
# Confirmed: Transaction version 6, tag bytes in serialization
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":"1","method":"getrawtransaction","params":["<txid>", 1]}' \
  http://localhost:18232 | jq '.result.version'
# Output: 6
```

---

## Phase 6: Zebra RPC Tag Exposure 🔶

**Status**: Not started

The `getrawtransaction` RPC returns V6 transaction data but doesn't include the `tag` field in the JSON response.

### Files to Update

| File                                         | Change                                        |
| -------------------------------------------- | --------------------------------------------- |
| `zebra-rpc/src/methods/types/transaction.rs` | Add `tag: [u8; 16]` to `OrchardAction` struct |
| `zebra-rpc/src/methods/types/transaction.rs` | Extract tag from action in conversion code    |

### Current OrchardAction struct (missing tag)

```rust
pub struct OrchardAction {
    cv: [u8; 32],
    nullifier: [u8; 32],
    rk: [u8; 32],
    cm_x: [u8; 32],
    ephemeral_key: [u8; 32],
    enc_ciphertext: [u8; 580],
    spend_auth_sig: [u8; 64],
    out_ciphertext: [u8; 80],
    // MISSING: tag: [u8; 16]
}
```

---

## Testing

### V5 Compatibility (Critical)

```rust
#[test]
fn v5_serialization_unchanged() {
    let v5_bytes = include_bytes!("test_vectors/v5_transaction.bin");
    let tx = Transaction::read(&v5_bytes[..]).unwrap();
    let mut output = Vec::new();
    tx.write(&mut output).unwrap();
    assert_eq!(v5_bytes.as_slice(), output.as_slice());
}
```

### V6 Round-Trip

```rust
#[cfg(all(zcash_unstable = "nu7", feature = "tx_v6"))]
#[test]
fn v6_with_tags_round_trip() {
    let tag = [0x42u8; 16];
    let tx = build_v6_transaction_with_tag(tag);
    // serialize, deserialize, verify tag preserved
}
```

---

## Checklist Before Merge

- [x] V5 transactions serialize identically to upstream
- [x] All V6/tag code gated with `#[cfg(zcash_unstable = "nu7")]`
- [x] NU7 activates correctly on regtest (`./dev up`)
- [x] Tag field included in V6 action serialization
- [x] Tag field NOT included in V5 action serialization
- [x] V5 builds without NU7 flags (`cargo check -p zebra-chain`)
- [x] End-to-end V6 transaction with tags ✅ **Verified 2026-01-13**
- [x] `zip-233` feature enabled in both zcash-devtool and Zebra
- [ ] Zebra RPC exposes tag field in JSON response
- [ ] Tag-keys commands tested (`show`, `export`, `generate`, `verify`)
- [ ] Scan-tags PIR pre-filtering tested
- [ ] Remove debug println! from shield.rs

---

## References

- [ZIP 230: Version 6 Transaction Format](https://zips.z.cash/zip-0230) (Draft)
- [ZIP 244: Transaction Identifier Non-Malleability](https://zips.z.cash/zip-0244)
- [NU7 Candidate ZIPs](https://zips.z.cash/#nu7-candidate-zips)
