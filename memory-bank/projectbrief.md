# Project Brief

## Overview
Z3: Building a modern, secure, reliable, scalable software stack that will replace Zcashd.

## Core Features
- A full-node implementation that implements the Zcash protocol (Zebra)
- A service that provides indexing and serves light clients blockchain data (Zaino) 
- A cli-wallet that provides wallet functionality that existed in Zcashd but that is not planned for implementation in Zebra (Zallet)
- A wrapper service that exposes the three previously mentioned services as a "single binary" to the users

## Target Users
- Developers of the Zcash protocol (including the Zcash Foundation, the Electric Coin Company, Shielded Labs, Zingo Labs and the broader community)
- Operators of centralized cryptocurrency exchanges (including Coinbase, Gemini, Kraken, Binance, etc.)
- Operators of decentralized cryptocurrency exchanges (including the Zcash DEX implemented with Near Intents)
- Operators of cryptocurrency wallet software platforms (including Zashi, Brave Wallet, etc.)
- Operators of ASIC based proof of work miners on the Zcash blockchain
- Operators of "finalizers" (known more commonly as validators) as Zcash prepares to transition to a hybrid Proof of Work / Proof of Stake consensus algorithm.
- Operators of block explorers on the Zcash network

## Technical Preferences (optional)
- [Zebra](https://github.com/ZcashFoundation/zebra) for the Zcash full node 
- [Zaino](https://github.com/zingolabs/zaino/) for the indexing service that will interface with Zebrad via RPC and the ReadStateService, and also replace the legacy go light client server [lightwalletd](https://github.com/zcash/lightwalletd)
- [Zallet](https://github.com/zcash/wallet) for the cli-wallet that will replace the wallet functionality that originally existed in Zcashd
- Other software components should be Rust based
- Security is of paramount importance
- Clippy as the Rust linter of choice
- Git and Github for SCM
- Github Actions for CI
- Test driven development
- Docker for deployment
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) as standard for SCM commit messaging
