# Product Context

## Problem

The Z3 project aims to replace the existing Zcashd software stack, which was forked from Bitcoin Core back in 2016. The c++ codebase has become difficult to maintain and extend. Zcashd is a monolithic application that includes full-node, indexing, and wallet functionalities. Replacing Zcashd with a modular and maintainable software stack addresses the following problems:

*   **Maintenance burden:** Zcashd's codebase is complex and challenging to maintain, leading to increased development costs and slower feature development.  The Zcash codebase has also diverged significally from upstream (Bitcoin Core) which means that tracking upstream security fixes has become quite an onerous task.
*   **Scalability limitations:** Zcashd's monolithic architecture limits its scalability and ability to handle increasing transaction volumes.
*   **Lack of flexibility:** Zcashd's tight integration of components makes it difficult to adapt to new technologies and requirements.
*   **Security risks:** Zcashd's complexity, and it's c++ codebase increases the risk of security vulnerabilities. The legacy architecture has key material in memory readable and writable by the same process that handles peer to peer networking (and everything else) which makes containing the blast radius of a memory corruption exploit difficult to impossible.


## Proposed Solution

This project proposes replacing Zcashd with a modular software stack consisting of the following components:

*   **[Zebra](https://github.com/ZcashFoundation/zebra):** A full-node implementation of the Zcash protocol that provides consensus and network functionalities.  Zebra has been under development by the Zcash Foundation since 2020 and is presently deployed by a number of decentralized node operators on mainnet.
*   **[Zaino](https://github.com/zingolabs/zaino/):** An indexing service that provides light clients with blockchain data, replacing the legacy go light client server lightwalletd. Zaino is under active development by Zingo Labs, funded by a grant from [ZCG](https://zcashcommunitygrants.org/).
*   **[Zallet](https://github.com/zcash/wallet):** A CLI wallet that provides wallet functionality that existed in Zcashd but is not planned for implementation in Zebra.  Zallet is under active development by the Electric Coin Company.
*   **Z3 Wrapper Service:** A wrapper service that exposes the three previously mentioned services as a "single binary" to the users.  Note that this capability could be achieved as a "single binary" that is deployed as a Debian package eg `sudo apt install zcash-z3`, or via Docker Compose or as a Helm chart.

This modular architecture offers several advantages:

*   **Improved maintainability:** Each component can be developed and maintained independently, reducing the overall maintenance burden.
*   **Enhanced scalability:** Each component can be scaled independently to meet specific demands.
*   **Increased flexibility:** The modular design allows for easier adaptation to new technologies and requirements.
*   **Reduced security risks:** Each component can be hardened and secured independently, reducing the overall attack surface.

## User Experience Goals

The project aims to provide a secure, reliable, and efficient experience for the following target users:

*   **Zcash protocol developers:** A well-documented and easy-to-use software stack that facilitates protocol development and experimentation.
*   **Centralized cryptocurrency exchanges:** A secure, scalable and reliable modern full-node implementation that supports exchange operations (deposit, withdrawal).
*   **Decentralized cryptocurrency exchanges:** A secure, scalable and reliable modern full-node implementation that supports decentralized exchange operations (deposit, withdrawal, swap).
*   **Cryptocurrency wallet software platforms:** A secure and user-friendly full-node implementation that provides essential wallet functionalities. (send, receive, check balance).
*   **Block explorers:** A scalable and reliable full-node implementation that provides fast access to archival blockchain data.

The key user experience goals include:

*   **Seamless upgrade:** The user can upgrade from the legacy (Zcashd) daemon to the modern (Z3) stack without changing any of their integration code.
*   **Security:** Protecting user funds and data from unauthorized access. Ensuring that the shielded supply remains free of counterfeiting bugs.
*   **Reliability:** Ensuring the software stack operates consistently and without errors.
*   **Observability:** Providing telemetry, logging and tracing to ensure proper operation in rugged production environments.
*   **Efficiency:** Providing fast and responsive performance.
*   **Usability:** Making the software stack easy to use and understand.

## Key Metrics
*   **% of mainnet nodes running Z3:** 0 as of April 2025, with a target of 2025 by the time Zcashd is deprecated.  Sources for determining this metric are TBD, some potential options include [Blockchair](https://blockchair.com/zcash/nodes)

## Further Reading

For technical details about the architecture and implementation, see the [Technical Context](techContext.md).
