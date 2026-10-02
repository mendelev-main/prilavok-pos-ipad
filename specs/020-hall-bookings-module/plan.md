# Implementation Plan: модуль зала и бронирований

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Вынести полный runtime карты зала и бронирований из `pos.html` в отдельный классический компонент.
Сохранить глобальный UI API и persisted-форматы, подключить production-файл к тестовой fixture и
добавить недостающие domain tests для времени и каскадного удаления.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Primary Dependencies**: UIKit, WKWebView, existing local storage adapter and DOM runtime
**Storage**: Existing `hallTables` and `bookings` localStorage records
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target Platform**: iPadOS 16+
**Project Type**: Native iPad shell with embedded local web application
**Performance Goals**: No new writes, timers, requests, or render passes
**Constraints**: Exact data/UI compatibility; offline-only; no version or Xcode project change
**Scale/Scope**: One contiguous hall/bookings domain of about 270 lines

## Constitution Check

*GATE: passed before research and re-checked after design.*

- Local POS remains the only source for hall and booking data.
- Existing keys and JSON are unchanged and require no migration.
- No network path or automatic synchronization is introduced.
- One coherent domain moves; payment, orders and analytics stay in place.
- Tests cover the production component and the build verifies packaging.

## Project Structure

```text
PrilavokPOS/Web/js/features/
├── web-orders.js
├── inventory.js
├── warehouse-reporting.js
└── hall-bookings.js

PrilavokPOS/pos.html
tests/product-stock.test.cjs
specs/020-hall-bookings-module/
```

**Structure Decision**: Continue feature-per-domain classic scripts while inline handlers remain.

## Complexity Tracking

No constitution violations require justification.
