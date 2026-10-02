# Implementation Plan: надёжная раздельная оплата

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Add a versioned optional split draft to current-order session snapshots. Journal each newly accepted
part before changing live paid state, validate recovery, guard navigation, and harden final input.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Storage**: existing `currentOrderSession` and `criticalStorageJournal`
**Testing**: Node.js 22 `node:test`; Xcode Simulator build and bundle checksum
**Target**: iPadOS 16+
**Constraints**: no new key, migration, network, auto sync, version or project-file edit

## Constitution Check

- Accepted money is represented locally before later UI/network work.
- The existing session remains readable because the new field is optional.
- Final receipt remains the same atomic products/orders/shifts/session commit.
- The change is bounded to payment durability and validation.

