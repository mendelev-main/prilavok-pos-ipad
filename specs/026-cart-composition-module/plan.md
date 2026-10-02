# Implementation Plan: модуль формирования корзины

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Перенести contiguous cart-composition block в classic feature script. Добавить отсутствующую
инициализацию swipe state и regression test. Остановить границу перед shared flash и parking runtime.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Dependencies**: product/recipe stock helpers, cart presentation, session persistence and modal helpers
**Storage**: unchanged `currentOrderSession`
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target**: iPadOS 16+
**Constraints**: preserve cart data/stock behavior; exclude critical commit operations

## Constitution Check

- Local session remains authoritative and is saved through the existing facade.
- Stock validation stays before in-memory mutation.
- No key, format, network, sync or version change.
- Parking/payment/check issuance remain outside the component.
- The one behavior fix is isolated and regression-tested.
