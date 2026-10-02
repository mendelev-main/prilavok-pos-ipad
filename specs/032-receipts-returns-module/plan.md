# Implementation Plan: чеки и возвраты

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Audit return atomicity and drawer accounting, add regression tests for confirmed defects, then extract the contiguous receipt/return runtime into a classic feature script while keeping the global API and data formats.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Dependencies**: payment receipt renderer, shift totals, critical storage journal, stock snapshots, loyalty retry and LAN print handoff
**Storage**: existing `prilavok_products`, `prilavok_orders`, `prilavok_shifts` and `prilavok_criticalStorageJournal`; unchanged shapes
**Testing**: Node.js 22 `node:test`; Xcode Simulator build and bundle checksum
**Target**: iPadOS 16+
**Constraints**: no receipt/storage migration, no UI redesign, no new network behavior, no version/project change

## Constitution Check

- POS remains offline-first and saves the complete return locally before loyalty networking.
- The existing return journal and historical stock snapshot remain authoritative.
- The stage changes only a confirmed cash-accounting defect and rejects corrupt numeric data.
- The module is loaded as a classic script before `loadAll()` and keeps legacy globals.
