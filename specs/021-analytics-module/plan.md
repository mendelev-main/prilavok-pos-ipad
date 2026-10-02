# Implementation Plan: модуль аналитики

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Вынести расчёт периода, локальных KPI, группировок, представление экрана и существующую загрузку
loyalty KPI из `pos.html` в отдельный классический компонент. Сохранить глобальный UI API, формулы,
роль администратора и offline fallback; подключить production-файл к общей test fixture.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Primary Dependencies**: UIKit, WKWebView, existing DOM/runtime and loyalty transport
**Storage**: Read-only access to existing orders, shifts and products in state
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target Platform**: iPadOS 16+
**Project Type**: Native iPad shell with embedded local web application
**Performance Goals**: No new writes, requests, timers or render passes
**Constraints**: Exact formula/UI/network compatibility; no version or Xcode project change
**Scale/Scope**: One analytics domain of about 180 lines

## Constitution Check

*GATE: passed before research and re-checked after design.*

- Local POS receipts remain authoritative for sales analytics.
- No key, JSON format or write path changes.
- Existing loyalty read remains isolated and failure-tolerant; no new trigger is introduced.
- One coherent domain moves; payment, warehouse reporting and settings stay in place.
- Tests execute the production component and the build verifies packaging.

## Project Structure

```text
PrilavokPOS/Web/js/features/
├── web-orders.js
├── inventory.js
├── warehouse-reporting.js
├── analytics.js
└── hall-bookings.js

PrilavokPOS/pos.html
tests/product-stock.test.cjs
specs/021-analytics-module/
```

**Structure Decision**: Continue feature-per-domain classic scripts while inline handlers remain.

## Complexity Tracking

No constitution violations require justification.
