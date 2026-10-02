# Implementation Plan: модуль оплаты

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Extract the contiguous payment and paid-receipt runtime into a classic feature script. Preserve exact
function bodies and global APIs, add module load/runtime tests, then run the full regression and build.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Dependencies**: cart totals, stock planner, current session, critical journal, loyalty and printer APIs
**Storage**: unchanged
**Testing**: Node.js 22 `node:test`; Xcode Simulator build and bundle checksum
**Target**: iPadOS 16+
**Constraints**: mechanical extraction; no payment behavior, version or project change

## Constitution Check

- Existing offline-first and storage-first ordering is preserved byte-for-byte in the moved block.
- Payment is moved only after specs 028–030 established its behavior and regressions.
- Returns and printer orchestration remain independent to keep the stage bounded.

