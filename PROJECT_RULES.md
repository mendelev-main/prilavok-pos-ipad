# Prilavok POS — Project Rules

## Source of truth

Prilavok POS iPad application is the single source of truth for operational data.

Rules:

1. The POS application must continue working reliably without internet connection.
2. Local POS data has the highest priority and is considered authoritative.
3. Synchronization with web/backend must never overwrite newer local POS data.
4. When local data changes and synchronization occurs, the web version must reflect the POS state.
5. Backend and web interfaces are secondary representations of POS data.
6. Any architecture changes must preserve offline operation.

## Development rules

- Never break existing working POS functionality when adding features.
- Before changing code, check dependencies between UI, data storage, synchronization and printing.
- Every new feature must be tested in four areas:
  - interface;
  - business logic;
  - local storage;
  - synchronization/display/printing.

## Priority order

1. Stable cash register operation.
2. Correct local data storage.
3. Safe synchronization.
4. New features.

## Architecture direction

The project should move toward clear separation:

- native iPad layer;
- web UI layer;
- business logic modules;
- local storage layer;
- synchronization layer.

Refactoring must be incremental and safe.
