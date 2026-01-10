# Upstream PR Candidates

Changes made during zforge development that should be contributed back to upstream repositories.

## Summary

| Repository | Change | Priority | Complexity | Status |
|------------|--------|----------|------------|--------|
| zaino | GetTreeState height=0 fix | High | Low | Ready |
| zcash-devtool | Regtest network support | Medium | High | Ready |
| zcash-devtool | --mnemonic flag for init | High | Low | Ready |

---

## Zaino

### Fix GetTreeState RPC for block height 0

**Commit:** `09b790cf`  
**Files:** `zaino-state/src/backends/fetch.rs`  
**Priority:** High  
**Complexity:** Low (7-line change)

**Problem:** When requesting tree state for height 0 (genesis block), the RPC handler incorrectly treated it as a hash request because height was falsy. This caused a parse error: "could not convert the input string to a hash or height".

**Fix:** Check if height is explicitly provided rather than checking if it's truthy.

**Before:**
```rust
let tree_state = if request.height != 0 {
    fetcher.get_treestate_by_height(request.height).await?
} else {
    // Incorrectly assumed hash request
}
```

**After:**
```rust
// Height 0 is valid (genesis block)
let tree_state = fetcher.get_treestate_by_height(request.height).await?;
```

**Why upstream wants this:** Bug affects any Regtest setup and edge cases on mainnet/testnet when querying genesis.

**PR Prep:**
1. Branch from `upstream/main`
2. Cherry-pick only the `fetch.rs` change (not the Cargo.lock)
3. Add test case if possible

---

## zcash-devtool

### Regtest Network Support

**Commits:** `e4f5668`, `e8fdd76`  
**Files:** 22 files across `src/`  
**Priority:** Medium  
**Complexity:** High (240+ lines changed)

**Problem:** zcash-devtool only supported Mainnet and Testnet. Regtest uses `LocalNetwork` which implements `Parameters` differently than `consensus::Network`, causing type mismatches throughout the codebase.

**Solution:** Created `NetworkParams` enum wrapper:

```rust
pub(crate) enum NetworkParams {
    Standard(consensus::Network),
    Regtest(LocalNetwork),
}

impl Parameters for NetworkParams {
    // Delegates to inner type
}
```

**Changes required:**
- Added `Regtest` variant to `Network` enum
- Created `NetworkParams` wrapper with `Parameters` impl
- Updated `WalletConfig` to store network type correctly
- Updated `Servers::pick()` to accept `&NetworkParams`
- Updated all 19 wallet/pczt command files to use `NetworkParams`

**Why upstream wants this:** Enables local development and testing without mainnet/testnet. Essential for protocol development.

**PR Prep:**
1. This is a significant feature - consider opening an issue first to discuss approach
2. May want to squash commits for cleaner history
3. Remove any zforge-specific patches from Cargo.toml before PR
4. Needs testing documentation

**Alternative approaches upstream might prefer:**
- Making everything generic over `P: Parameters` (cleaner but bigger refactor)
- Using feature flags for regtest support

---

### --mnemonic Flag for Non-Interactive Init

**Commit:** `5610f6e`  
**Files:** `src/commands/wallet/init.rs`  
**Priority:** High  
**Complexity:** Low (21 lines)

**Problem:** `wallet init` uses `rpassword` for interactive mnemonic entry, which fails in:
- CI/CD pipelines
- Automated testing
- Scripts

**Solution:** Added `--mnemonic` flag to provide mnemonic directly:

```rust
#[arg(long, help = "Mnemonic phrase (24 words, for non-interactive use)")]
mnemonic: Option<String>,

// In run():
let mnemonic = if let Some(m) = opts.mnemonic {
    m
} else {
    // Interactive prompt
};
```

**Why upstream wants this:** Essential for any automated testing or CI integration.

**PR Prep:**
1. Simple cherry-pick from `pr/*` branch
2. Consider adding to `init-fvk` as well for consistency
3. Add CLI help text about security implications

---

## NOT for Upstream

These changes are zforge-specific and should not be PRed:

### Zaino
- `b279b311` - Add zebra-chain to local patches
- `b1479776` - Add local patches for tag-PIR development

### zcash-devtool
- `4863d0d` - Use local submodule paths for zforge development

These modify `Cargo.toml` `[patch.crates-io]` sections to use local paths, which only make sense for our development setup.

---

## PR Workflow

For each PR:

```bash
cd <submodule>
git fetch upstream
git checkout -b pr/<feature-name> upstream/main
git cherry-pick <commits>
# Remove any zforge-specific Cargo.toml patches
git push origin pr/<feature-name>
# Open PR: greg-nagy/<repo>:pr/<feature-name> → zingolabs/<repo>:main
```

## Recommended Order

1. **Zaino GetTreeState fix** - Small, clear bug fix, easy win
2. **zcash-devtool --mnemonic flag** - Small, useful, non-controversial
3. **zcash-devtool Regtest support** - Larger, discuss approach first
