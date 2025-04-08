# Tech Context

## Technologies Used

*   **Rust:** Primary language for Zebra, Zaino, and Zallet (version TBD). Justification: Security, performance, and memory safety.
*   **gRPC:** For communication between Zebra and Zaino (version TBD). Justification: Efficient and standardized RPC framework.
*   **Docker:** For deployment and containerization (version TBD). Justification: Consistent and reproducible environments.
*   **Potentially: RocksDB or similar embedded database for Zaino's indexing** (version TBD). Justification: Efficient storage and retrieval of blockchain data.

## Development Setup

*   **Rust toolchain:** Requires a recent version of the Rust toolchain, including `rustc`, `cargo`, and `clippy`.
*   **Docker:** Requires Docker for building and running the services.
*   **Git:** Requires Git for version control.
*   **Editor:** VSCode with Rust Analyzer extension recommended.

## Technical Constraints

*   **Performance:** The system must be able to handle high transaction volumes and provide low-latency access to blockchain data.
*   **Security:** Security is paramount, and all components must be designed to resist attacks.
*   **Compatibility:** The system must be compatible with the Zcash protocol and network.

## Dependencies

*   `zebra-chain`, `zebra-consensus`, `zebra-network`, `zebra-state`: Zebra's core crates for blockchain functionality.
*   `tokio`: Asynchronous runtime for Rust.
*   `anyhow`: Flexible error handling library.

## Tool Usage Patterns

*   `cargo`: For building, testing, and managing dependencies.
*   `clippy`: For linting and code quality checks.
*   `git`: For version control and collaboration.
*   `docker`: For building and running containers.
