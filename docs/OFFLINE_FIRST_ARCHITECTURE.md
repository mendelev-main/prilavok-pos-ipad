# Prilavok POS — Offline-First Architecture

## Core rule

The iPad POS is the authoritative source of operational data.

## Required behavior

1. The POS must continue operating if internet access is lost.
2. Sales, receipts, shifts, catalog changes and local settings must be committed locally before any remote synchronization is attempted.
3. Remote services are synchronization targets, not the primary database for live POS operation.
4. A server response must never silently overwrite newer local POS state.
5. Synchronization must be retryable and must not block checkout, receipt creation, printing or shift operations.
6. Every migration from `pos.html` into modules must be incremental and verified on a physical iPad before the next migration step.

## Manual synchronization requirement

Synchronization is USER-INITIATED ONLY.

The application must not automatically synchronize after a local data change, on a timer, in the background, on launch, on reconnect, or when network availability changes.

The only permitted synchronization trigger is the existing synchronization button in:

`Настройки → Сетевые настройки`

Required flow:

1. A user changes data in the POS.
2. The change is saved locally on the iPad immediately.
3. The POS continues operating normally, regardless of internet availability.
4. The local state may be marked as having pending synchronization changes.
5. No network synchronization is started automatically.
6. The user opens `Настройки → Сетевые настройки` and presses the existing synchronization button.
7. Only then may the POS send its current authoritative local state to the backend.
8. The backend/web version is updated from POS data.
9. If synchronization fails, local POS data remains unchanged and POS operation continues normally.

## Synchronization direction and conflict rule

Authoritative direction:

`iPad POS → Backend → Web / Mini App`

The iPad POS remains the source of truth.

Remote data must not overwrite authoritative local POS data during normal synchronization. Any future remote-to-POS import feature must be designed as a separate explicit user action and must not be part of the standard synchronization button unless separately approved.

## Synchronization status UX

The Network Settings screen should eventually expose clear synchronization state, for example:

- pending local changes;
- last successful synchronization time;
- synchronization in progress;
- synchronization succeeded;
- synchronization failed / no connection.

A failed synchronization must never prevent sales or other local POS operations.

## Application version visibility requirement

The POS must always expose its current application version in the Settings screen so it is easy to verify which build is running on the iPad during testing and support.

The version is displayed in the `Настройки` screen inside the `Быстрые настройки` module, aligned on the right side of the module header.

Required UI behavior:

1. The left side of the header remains `Быстрые настройки`.
2. The right side displays the current version in a compact form, for example `Версия 130.14`.
3. The version label must be visually secondary and must not compete with the quick-action buttons.
4. The version must be updated whenever the POS application version is advanced.
5. This version indicator is a permanent diagnostics/support element and should not be removed during future UI refactors.

## Migration sequence

1. Add inactive module boundaries.
2. Document the existing data model and persistence points.
3. Introduce a local storage adapter behind the existing behavior.
4. Introduce manual synchronization orchestration with no automatic triggers.
5. Add durable pending-change tracking if required by the selected sync payload strategy.
6. Move one business domain at a time from `pos.html` into modules.
7. Keep printing and checkout regression tests mandatory after each move.

## v130.12 scope

This version added the future module structure. None of the new files were connected to `pos.html`, so existing runtime behavior remained unchanged.

## v130.13 requirement change

The synchronization design is now explicitly manual-only. The existing button in `Настройки → Сетевые настройки` is the sole approved trigger for standard POS-to-backend synchronization. Automatic/background synchronization is prohibited unless this requirement is intentionally changed later.

## v130.14 requirement change

The `Быстрые настройки` module must display the current POS application version on the right side of its header. This version indicator is retained as a permanent support and test-verification element.
