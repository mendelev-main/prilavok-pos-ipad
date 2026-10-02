# Implementation Plan: модуль кассовых смен

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Audit shift totals and side-effect ordering, cover a complete mixed shift, reject corrupt derived cash before mutation, then consolidate the distributed shift runtime into a classic feature module with the same global API.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Dependencies**: state/storage journal, receipts/payment, employee list, Telegram configuration, native printer bridge and formatting/modal helpers
**Storage**: existing `prilavok_shifts`, orders and critical journal; unchanged shapes
**Testing**: Node.js 22 `node:test`; Xcode Simulator build and bundle checksum
**Target**: iPadOS 16+
**Constraints**: preserve current UI, admin password, storage, external payloads, version and project file

## Constitution Check

- Shift mutations remain offline-first and durable before UI success or external reports.
- No local data is migrated, normalized or silently overwritten.
- Confirmed numeric corruption is blocked rather than repaired or uploaded.
- The module preserves global handlers required by inline UI and other feature scripts.
