# Tag Field Implementation Plan

> Protocol change to add 16-byte unencrypted detection tags to Orchard actions.
> **Requires NU7 network upgrade and V6 transaction format.**

## Overview

| Component           | Repository       | Key Files                           | Status         |
| ------------------- | ---------------- | ----------------------------------- | -------------- |
| Protocol layer      | `orchard/`       | `src/action.rs`, `src/tag.rs`       | ✅ Done        |
| Transaction builder | `librustzcash/`  | `zcash_primitives/src/transaction/` | ✅ Done        |
| Node parsing        | `zebra/`         | `zebra-chain/src/orchard/`          | 🔲 Not started |
| Indexing            | `zaino/`         | `zaino-state/src/`                  | 🔲 Not started |
| Wallet CLI          | `zcash-devtool/` | `src/`                              | 🔲 Not started |

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

### librustzcash (6 commits on feature/tag-field)

| File                                   | Change                                          |
| -------------------------------------- | ----------------------------------------------- |
| `zcash_primitives/.../orchard.rs`      | `read/write_action_without_auth_v6` (gated)     |
| `zcash_primitives/.../orchard.rs`      | `read/write_v6_bundle` now use V6 action funcs  |
| `zcash_client_backend/src/proto.rs`    | CompactOrchardAction ↔ CompactAction with tag   |
| `zcash_client_backend/src/scanning.rs` | `matches_tag()` for PIR pre-filtering           |
| `compact_formats.proto`                | Added `bytes tag = 5` to CompactOrchardAction   |

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
- [x] Verify V5 paths unchanged with `./dev check`
- [ ] Add round-trip tests for V6 bundles with tags (future)

---

## Phase 2: Zebra Implementation

**Key Principle**: V5 serialization MUST NOT CHANGE.

### Zebra Convention

Zebra uses a **single `Action` type shared between Transaction::V5 and Transaction::V6**.
Version awareness happens at the Transaction level, not with separate ActionV5/ActionV6 types.

```
Transaction::V1 ─┐
Transaction::V2 ─┤
Transaction::V3 ─┼─ (no Orchard)
Transaction::V4 ─┘
Transaction::V5 ─┬─ orchard::ShieldedData ─── Action (shared type)
Transaction::V6 ─┘
```

### 2.1 Add Tag Field to Action

**File:** `zebra-chain/src/orchard/action.rs`

```rust
pub struct Action {
    pub cv: ValueCommitment,
    pub nullifier: Nullifier,
    pub rk: VerificationKeyBytes<SpendAuth>,
    pub cm_x: pallas::Base,
    pub ephemeral_key: EphemeralPublicKey,
    pub enc_ciphertext: EncryptedNote,
    pub out_ciphertext: WrappedNoteKey,

    /// Detection tag (V6/NU7+ only, zeros for V5)
    #[cfg(all(zcash_unstable = "nu7", feature = "tx_v6"))]
    pub tag: [u8; 16],
}
```

### 2.2 Version-Aware Serialization Methods

Replace the single `ZcashSerialize`/`ZcashDeserialize` impl with version-specific methods:

```rust
impl Action {
    /// Serialize in V5 format (no tag)
    pub fn zcash_serialize_v5<W: Write>(&self, mut writer: W) -> io::Result<()> {
        self.cv.zcash_serialize(&mut writer)?;
        writer.write_all(&<[u8; 32]>::from(self.nullifier)[..])?;
        writer.write_all(&<[u8; 32]>::from(self.rk)[..])?;
        writer.write_all(&<[u8; 32]>::from(self.cm_x)[..])?;
        self.ephemeral_key.zcash_serialize(&mut writer)?;
        self.enc_ciphertext.zcash_serialize(&mut writer)?;
        self.out_ciphertext.zcash_serialize(&mut writer)?;
        // NO tag for V5
        Ok(())
    }

    /// Serialize in V6 format (with tag)
    #[cfg(all(zcash_unstable = "nu7", feature = "tx_v6"))]
    pub fn zcash_serialize_v6<W: Write>(&self, mut writer: W) -> io::Result<()> {
        self.zcash_serialize_v5(&mut writer)?;  // Reuse V5 fields
        writer.write_all(&self.tag)?;            // Add tag
        Ok(())
    }
}
```

### 2.3 Route in Transaction Serialization

**File:** `zebra-chain/src/transaction/serialize.rs`

The Transaction serialization already routes by version. Update orchard serialization:

```rust
// In Transaction::zcash_serialize:
match self {
    Transaction::V5 { orchard_shielded_data, .. } => {
        if let Some(orchard) = orchard_shielded_data {
            for action in &orchard.actions {
                action.zcash_serialize_v5(&mut writer)?;  // V5 format
            }
        }
    }
    #[cfg(all(zcash_unstable = "nu7", feature = "tx_v6"))]
    Transaction::V6 { orchard_shielded_data, .. } => {
        if let Some(orchard) = orchard_shielded_data {
            for action in &orchard.actions {
                action.zcash_serialize_v6(&mut writer)?;  // V6 format with tag
            }
        }
    }
}
```

**Tasks:**

- [ ] Add `tag: [u8; 16]` field to Action (gated with cfg)
- [ ] Implement `zcash_serialize_v5` / `zcash_deserialize_v5`
- [ ] Implement `zcash_serialize_v6` / `zcash_deserialize_v6` (gated)
- [ ] Update Transaction serialization to call version-specific methods
- [ ] Update Transaction deserialization similarly
- [ ] Add V5 compatibility tests (byte-for-byte identical)

---

## Phase 3: Zaino Implementation

**Key Principle**: Parse based on transaction version.

**File:** `zaino-fetch/src/chain/transaction.rs`

```rust
impl ParseFromSlice for Action {
    fn parse_from_slice(data: &[u8], tx_version: u32) -> Result<(&[u8], Self)> {
        // ... existing fields ...

        // Only read tag for V6+ transactions
        let tag = if tx_version >= 6 {
            read_bytes(&mut cursor, 16)?
        } else {
            vec![]  // Empty for V5
        };

        Ok((/* ... */))
    }
}
```

**Tasks:**

- [ ] Pass transaction version through parsing chain
- [ ] Only read tag bytes for V6 transactions
- [ ] Update CompactOrchardAction to include tag (proto already done)
- [ ] Index tags for V6 transactions

---

## Phase 4: NU7 Regtest Activation

### Build Configuration

```bash
# Build with NU7 features
./dev build --nu7

# Or manually:
export RUSTFLAGS='--cfg zcash_unstable="nu7"'
cargo build --features tx_v6
```

### Regtest Configuration

In librustzcash `LocalNetwork`:

```rust
let regtest = LocalNetwork {
    // ... earlier upgrades at block 1 ...
    nu6_1: Some(BlockHeight::from_u32(1)),
    #[cfg(zcash_unstable = "nu7")]
    nu7: Some(BlockHeight::from_u32(1)),  // Enable NU7 from block 1
};
```

**Tasks:**

- [ ] Configure librustzcash LocalNetwork for NU7
- [ ] Configure Zebra regtest for NU7 activation
- [ ] Document build flags in README

---

## Phase 5: Wallet CLI (zcash-devtool)

**After Phases 1-4 are complete**, implement wallet integration:

- [ ] Tag key derivation from FVK
- [ ] `tag-keys show/export/generate/verify` commands
- [ ] `scan-tags` command using PIR pre-filtering
- [ ] Transaction sending with tags

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

- [ ] V5 transactions serialize identically to upstream
- [ ] All V6/tag code gated with `#[cfg(zcash_unstable = "nu7")]`
- [ ] NU7 activates correctly on regtest
- [ ] Tag field included in V6 action serialization
- [ ] Tag field NOT included in V5 action serialization
- [ ] `./dev check` passes

---

## References

- [ZIP 230: Version 6 Transaction Format](https://zips.z.cash/zip-0230) (Draft)
- [ZIP 244: Transaction Identifier Non-Malleability](https://zips.z.cash/zip-0244)
- [NU7 Candidate ZIPs](https://zips.z.cash/#nu7-candidate-zips)
