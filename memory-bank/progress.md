# Progress

## Working Functionality

The Memory Bank is functional and being actively maintained. The core files (`projectbrief.md`, `productContext.md`, `systemPatterns.md`, `techContext.md`, `activeContext.md`, and `progress.md`) are being used to document the project.  RPC's exposed by Zcashd have been enumerated and documented. RPC's that have been surfaced by customers have been documented, and the Z3 development teams have mostly agreed upon which service (Zebra, Zaino or Zallet) will serve which method.  See the [RPC to service map](./data/rpc_mapping.md) for reference.

## Functionality Left To Build

The entire software stack (Zebra, Zaino, Zallet, and the wrapper service) still needs to be built.  Zebra is the closest to being "ready", but significant work remains to hit the [Zebra Ready for zcashd Deprecation milestone](https://github.com/orgs/ZcashFoundation/projects/9/views/11).  Zaino is under active development, and as of the DevSummit in Sofia in March 2025 we understand that releases are cut that can serve as drop-in replacements for Lightwalletd. Zallet is also under active development.

## Current Status

The project is in the initial planning and documentation phase. The Memory Bank is being established as a central repository for project knowledge. The core memory bank files have been reviewed and updated. The next steps are to have the teams focus on the list of RPC's that need to be supported by Z3 and ensure that the routing of method to service is correct and ensure that all teams have the same understanding.

## Known Issues

No known issues at this time.

## Evolution of Decisions

The most significant decisions that have been made to date are reflected in the mapping of RPC methods to backend services that was made by the Zcashd Deprecation Team in partnership with customers to figure out which methods exposed by Zcashd are in-use and which components of the new Z3 stack (Zebra, Zaino or Zallet) will service each method.  Note that the RPC Method Support list seems to be imcomplete, with many methods indicating that they will be served by either Zebra or Zaino or both. We urgently need to drive these decisions to ground in order to move forward.

We have identified the RPC methods that are most important to support in the new Z3 stack, based on the RPC method support file. We have also documented this information in `memory-bank/techContext.md`.

