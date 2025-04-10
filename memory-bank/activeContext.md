# Active Context

## Current Focus

Develop an architecture for the Z3 wrapper application that will allow it to correctly route RPC requests to Zebra, Zaino or Zallet.

Updating the Memory Bank, specifically reviewing and updating the core files (`projectbrief.md`, `productContext.md`, `systemPatterns.md`, `techContext.md`, `activeContext.md`, and `progress.md`).

## Recent Changes

Read all memory bank files (`projectbrief.md`, `productContext.md`, `systemPatterns.md`, `techContext.md`, `activeContext.md`, and `progress.md`).
Enumerated all of the RPC methods that zcashd exposes.  Reviewed the list of RPC methods that customers said they depend on, and the [mapping](./data/rpc_mapping.md) (proposed by the Zcashd Deprecation Team) of which RPC method should be handled by which service in the new architecture.

## Active Decisions

No active decisions are currently being made.

## Important Patterns

The importance of maintaining a comprehensive and up-to-date Memory Bank is a key pattern for this project. All decisions and changes should be documented in the Memory Bank to ensure consistency and knowledge sharing.

## Learnings and Insights

The project brief provides a good overview of the project's goals and requirements, which is essential for making informed decisions. The modular architecture of the system allows for independent development and deployment of components.

The RPC method support file provides a valuable overview of which RPC methods are most important to support in the new Z3 stack. This information will be used to guide the development of the Z3 wrapper around the Zebra, Zaino, and Zallet components.
