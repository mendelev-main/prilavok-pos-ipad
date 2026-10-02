# Implementation Plan: модуль отложенных заказов

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Move the contiguous parked-order runtime into a classic feature component. Preserve park/resume code
and replace only `deleteParked` with a storage-first critical journal operation.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Dependencies**: cart/session, critical storage journal, kitchen print and loyalty helpers
**Storage**: existing `parked`, `currentOrderSession`, `criticalStorageJournal`
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target**: iPadOS 16+
**Constraints**: retain recovery behavior and data shapes; exclude payment

## Constitution Check

- Local POS remains authoritative.
- Critical parked mutations are durable before UI state changes.
- Existing keys and shapes stay unchanged.
- No network or automatic synchronization.
- Payment and receipt paths remain untouched.
