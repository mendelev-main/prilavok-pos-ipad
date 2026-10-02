# Implementation Plan: событийная публикация остатков

## Context

**Runtime**: classic JavaScript in WKWebView
**Storage source**: persisted `products`, `network`, `webAvailabilityRevision`
**Network**: existing `POST /api/availability/snapshot`
**Triggers**: completed stock-changing commits and explicit menu synchronization

## Constitution Check

- POS remains source of truth and local commit completes before network.
- Network never blocks or rolls back local operations.
- Ten-minute, launch, foreground and connectivity triggers are removed by explicit user decision.
- Product/storage formats and manual catalog synchronization remain unchanged.
- The accepted offline risk is documented rather than hidden by automatic retry.

## Design

Create `Web/js/features/availability.js`. A public `publishAvailability()` marks a pending generation
and starts one background drain. The drain reads products from storage for every generation. A trigger
during fetch sets pending again, so a second newest snapshot follows. Failure stops the drain without
timer/reconnect retry. `onAvailabilityAppState(false)` only aborts an in-flight request.

Call `void publishAvailability()` immediately after successful local publication in payment, return,
receiving, inventory and product persistence modules. Remove `startAvailabilitySchedule()` and its
startup/foreground behavior. Keep the existing explicit call after successful manual menu sync.

## Validation

Add module boundary, no-heartbeat, commit-order, failure isolation and coalescing regressions before
implementation. Run full Node, production syntax, diagnostics, unsigned Simulator build and bundle hash.
