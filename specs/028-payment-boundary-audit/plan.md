# Implementation Plan: аудит границы оплаты

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Read and trace the current payment runtime without moving it. Map all persistent writes and external
effects, verify existing tests, reproduce boundary risks, and leave runtime fixes to a new spec.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Storage**: existing `products`, `orders`, `shifts`, `currentOrderSession`, `criticalStorageJournal`
**Testing**: Node.js 22 `node:test`; static source inspection
**Target**: iPadOS 16+
**Constraints**: audit only; no production-code, key, shape, UI, network, version or project change

## Constitution Check

- Local data remains authoritative and is inspected before network side effects.
- Confirmed fixes are isolated in their own feature specs.
- Manual iPad checks remain deferred to the final acceptance pass.

