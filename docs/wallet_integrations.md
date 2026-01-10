# Phase 2: Wallet Ecosystem Integration

**Status:** Planned (after Phase 1 core protocol changes)  
**Goal:** E2E UX demo across iOS, Android, and Desktop with unified sync/restore

## Priorities

1. **Adoption** — Reach the most users (official Zashi apps)
2. **Integration** — Multiple pieces working in tandem (Zaino ↔ wallets)

## Target Stack

```
z3/
├── ─── CORE (Phase 1) ───────────────────────────
│   ├── zebra/              # Full node
│   ├── zaino/              # Indexer (Zingolabs)
│   ├── orchard/            # Protocol changes (tag field)
│   ├── librustzcash/       # Libraries
│   └── zcash-devtool/      # CLI testing
│
├── ─── MOBILE (Priority: Adoption) ───────────────
│   ├── zcash-light-client-ffi/   # Rust FFI layer
│   ├── zcash-swift-wallet-sdk/   # iOS SDK
│   ├── zcash-android-wallet-sdk/ # Android SDK
│   ├── zashi-ios/                # Official iOS app
│   └── zashi-android/            # Official Android app
│
└── ─── DESKTOP (Priority: Integration) ───────────
    └── zingo-pc/                 # Desktop (same team as Zaino)
```

## Why These Choices

### Mobile: Zashi (Official ECC Wallet)
- **Highest adoption** — Official Zcash wallet, ECC-promoted
- **App Store presence** — Featured, trusted
- **SDK quality** — Production-grade, well-documented
- Changes propagate to largest user base via app updates

### Desktop: Zingo-pc (Zingolabs)
- **Same team as Zaino** — Guaranteed integration coherence
- **Actively maintained** — Regular updates
- **Pure Zcash focus** — Not diluted by 100 other coins

### Why NOT Others

| Alternative | Reason to Skip |
|-------------|----------------|
| ZecWallet Lite | ☠️ Archived/dead since 2022 |
| Zkool2 | Lower adoption (not official) |
| Exodus | Closed source, Zcash is 1/100+ coins |
| Build custom | Zero adoption, massive effort |

## Dependency Chain

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PROTOCOL CHANGES FLOW                            │
│                                                                     │
│  orchard ──► librustzcash ──┬──► zcash-light-client-ffi            │
│  (tag field)                │         │                             │
│                             │         ├──► swift-wallet-sdk         │
│                             │         │         └──► Zashi iOS      │
│                             │         │                             │
│                             │         └──► android-wallet-sdk       │
│                             │                   └──► Zashi Android  │
│                             │                                       │
│                             └──► zaino ──► lightwalletd protocol    │
│                                  (indexes tags)    │                │
│                                                    ▼                │
│                                              zingo-pc (desktop)     │
└─────────────────────────────────────────────────────────────────────┘

All wallets query Zaino via lightwalletd gRPC protocol (service.proto)
```

## Submodule Additions

### Step 1: Add Mobile FFI Layer
```bash
cd z3
mkdir -p mobile
git submodule add https://github.com/Electric-Coin-Company/zcash-light-client-ffi mobile/zcash-light-client-ffi
```

### Step 2: Add Mobile SDKs
```bash
git submodule add https://github.com/Electric-Coin-Company/zcash-swift-wallet-sdk mobile/zcash-swift-wallet-sdk
git submodule add https://github.com/Electric-Coin-Company/zcash-android-wallet-sdk mobile/zcash-android-wallet-sdk
```

### Step 3: Add Zashi Apps
```bash
git submodule add https://github.com/Electric-Coin-Company/zashi-ios mobile/zashi-ios
git submodule add https://github.com/Electric-Coin-Company/zashi-android mobile/zashi-android
```

### Step 4: Add Desktop
```bash
mkdir -p desktop
git submodule add https://github.com/zingolabs/zingo-pc desktop/zingo-pc
```

## Build Requirements

### iOS (Zashi)
- macOS with Xcode 15+
- Apple Developer account (for TestFlight)
- Rust toolchain with iOS targets
- CocoaPods or Swift Package Manager

### Android (Zashi)
- Android Studio
- Android SDK
- Rust toolchain with Android NDK targets
- Gradle

### Desktop (Zingo-pc)
- Node.js 18+
- Electron
- Platform-specific build tools

## Deployment Targets

| Platform | Build | Internal Testing | Production |
|----------|-------|------------------|------------|
| iOS | Xcode Archive | TestFlight | App Store |
| Android | Gradle APK | Firebase App Distribution | Play Store |
| macOS | Electron → DMG | Direct install | GitHub Releases / Homebrew |
| Linux | Electron → AppImage | Direct install | Flatpak / Snap |
| Windows | Electron → exe | Direct install | GitHub Releases |
| Server | Docker Compose | Local | Cloud / VPS |

## Incremental Integration Plan

### Phase 2a: FFI + SDK Only (No Apps)
Goal: Verify protocol changes flow through to SDK layer

```
z3/
├── (core submodules)
└── mobile/
    ├── zcash-light-client-ffi/
    ├── zcash-swift-wallet-sdk/
    └── zcash-android-wallet-sdk/
```

Test: Build SDK, run SDK tests against local Zaino

### Phase 2b: Add Zashi Apps
Goal: Full mobile E2E on Regtest

```
z3/mobile/
├── (SDKs)
├── zashi-ios/
└── zashi-android/
```

Test: Run Zashi on simulator → connect to local Zaino → sync wallet

### Phase 2c: Add Desktop
Goal: Complete platform coverage

```
z3/desktop/
└── zingo-pc/
```

Test: Run Zingo-pc → connect to local Zaino → verify tag queries work

## Procfile Evolution

### Phase 1 (Current)
```
zebra: cargo run --release -p zebrad ...
zaino: cargo run --release -p zainod ...
```

### Phase 2 (With Wallets)
```
zebra: cargo run --release -p zebrad ...
zaino: cargo run --release -p zainod ...
# Mobile handled via Xcode/Android Studio
# Desktop:
zingo: cd desktop/zingo-pc && npm run dev
```

## Version Pinning Strategy

Mobile SDKs pin librustzcash versions. Need to coordinate:

| SDK | librustzcash version | Notes |
|-----|---------------------|-------|
| zcash-light-client-ffi | Check Cargo.toml | Must match z3 fork |
| zcash-swift-wallet-sdk | Via FFI | - |
| zcash-android-wallet-sdk | Has own backend-lib | Check separately |

Strategy: Fork SDKs if needed to patch librustzcash/orchard references to local paths.

## Success Criteria

1. **iOS**: Zashi on TestFlight syncs via local Zaino, sees tag-indexed data
2. **Android**: Zashi APK syncs via local Zaino, sees tag-indexed data
3. **Desktop**: Zingo-pc syncs via local Zaino, sees tag-indexed data
4. **Server**: Zebra + Zaino deployed, wallets connect remotely

## Future Considerations

### Admin UI (Phase 3?)
Lightweight dashboard showing:
- Service health (Zebra, Zaino)
- Chain sync status
- Indexed tag statistics
- Test wallet management

### PIR Indexer (Phase 3?)
When PIR implementation is ready:
- Add PIR indexer service
- Database for tag → transaction mapping
- Query API for clients

## Related Docs

- [PLAN_PHASE1_CORE.md](./PLAN_PHASE1_CORE.md) — Current core protocol work
- [UPSTREAM_PR_CANDIDATES.md](./UPSTREAM_PR_CANDIDATES.md) — Changes to upstream
