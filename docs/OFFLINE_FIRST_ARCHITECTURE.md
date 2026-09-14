# Prilavok POS — Offline-First Architecture

## Core rule

The iPad POS is the authoritative source of operational data.

## Required behavior

1. The POS must continue operating if internet access is lost.
2. Sales, receipts, shifts and local settings must be committed locally before any remote synchronization is attempted.
3. Remote services are synchronization targets, not the primary database for live POS operation.
4. A server response must never silently overwrite newer local POS state.
5. Synchronization must be retryable and must not block checkout, receipt creation or shift operations.
6. Every migration from `pos.html` into modules must be incremental and verified on a physical iPad before the next migration step.

## Migration sequence

1. Add inactive module boundaries.
2. Document the existing data model and persistence points.
3. Introduce a local storage adapter behind the existing behavior.
4. Add a durable sync queue.
5. Move one business domain at a time from `pos.html` into modules.
6. Keep printing and checkout regression tests mandatory after each move.

## v130.12 scope

This version only adds the future module structure. None of the new files are connected to `pos.html` yet, so existing runtime behavior remains unchanged.
