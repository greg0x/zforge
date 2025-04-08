# Product Context

## Problem

The Z3 project aims to replace the existing Zcashd software stack, which was forked from Bitcoin Core back in 2016. The c++ codebase has become difficult to maintain and extend. Zcashd is a monolithic application that includes full-node, indexing, and wallet functionalities. Replacing Zcashd with a modular and maintainable software stack addresses the following problems:

*   **Maintenance burden:** Zcashd's codebase is complex and challenging to maintain, leading to increased development costs and slower feature development.
*   **Scalability limitations:** Zcashd's monolithic architecture limits its scalability and ability to handle increasing transaction volumes.
*   **Lack of flexibility:** Zcashd's tight integration of components makes it difficult to adapt to new technologies and requirements.
*   **Security risks:** Zcashd's complexity, and it's c++ codebase increases the risk of security vulnerabilities. 


## Proposed Solution

This project proposes replacing Zcashd with a modular software stack consisting of the following components:

*   **Zebra:** A full-node implementation of the Zcash protocol that provides consensus and network functionalities.
*   **Zaino:** An indexing service that provides light clients with blockchain data, replacing the legacy go light client server lightwalletd.
*   **Zallet:** A CLI wallet that provides wallet functionality that existed in Zcashd but is not planned for implementation in Zebra.
*   **Wrapper Service:** A wrapper service that exposes the three previously mentioned services as a "single binary" to the users

This modular architecture offers several advantages:

*   **Improved maintainability:** Each component can be developed and maintained independently, reducing the overall maintenance burden.
*   **Enhanced scalability:** Each component can be scaled independently to meet specific demands.
*   **Increased flexibility:** The modular design allows for easier adaptation to new technologies and requirements.
*   **Reduced security risks:** Each component can be hardened and secured independently, reducing the overall attack surface.

## User Experience Goals

The project aims to provide a secure, reliable, and efficient experience for the following target users:

*   **Zcash protocol developers:** A well-documented and easy-to-use software stack that facilitates protocol development and experimentation.
*   **Centralized cryptocurrency exchanges:** A secure, scalable and reliable modern full-node implementation that supports exchange operations (deposit, withdrawal)
*   **Decentralized cryptocurrency exchanges:** A secure, scalable and reliable modern full-node implementation that supports decentralized exchange operations (deposit, withdrawal, swap)
*   **Cryptocurrency wallet software platforms:** A secure and user-friendly full-node implementation that provides essential wallet functionalities. (send, receive, check balance)
*   **Block explorers:** A scalable and reliable full-node implementation that provides fast access to archival blockchain data

The key user experience goals include:

*   **Seamless upgrade:** The user can upgrade from the legacy (Zcashd) daemon to the modern (Z3) stack without changing any of their integration code.
*   **Security:** Protecting user funds and data from unauthorized access. Ensuring that the shielded supply remains free of counterfeiting bugs.
*   **Reliability:** Ensuring the software stack operates consistently and without errors.
*   **Observability:** Providing telemetry, logging and tracing to ensure proper operation in rugged production environments.
*   **Efficiency:** Providing fast and responsive performance.
*   **Usability:** Making the software stack easy to use and understand.
