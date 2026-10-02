# Implementation Plan: модуль складской аналитики

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/019-warehouse-reporting-module/spec.md`

## Summary

Вынести read-only расчёт складского отчёта, страницу выбора периода, формирование секций и передачу
PDF/XLSX payload из `pos.html` в отдельный классический JavaScript-компонент. Сохранить глобальные
UI-контракты, вычисления, native actions и использование payload из Telegram-кода.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Primary Dependencies**: UIKit, WebKit/WKWebView, existing native PDF/XLSX message bridge
**Storage**: Read-only access to existing POS state; no report persistence
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target Platform**: iPadOS 16+
**Project Type**: Native iPad shell with an embedded local web application
**Performance Goals**: No new storage writes, requests, timers, or additional report passes
**Constraints**: Exact calculation/UI/payload compatibility; no version or `project.pbxproj` change
**Scale/Scope**: One contiguous warehouse-reporting domain of about 170 lines and existing regression scenarios

## Constitution Check

*GATE: passed before research and re-checked after design.*

- **Local POS remains source of truth**: reports derive from local products, receipts and orders.
- **Compatibility is preserved**: no persisted schema, backup field, report payload or native action changes.
- **Network boundaries stay unchanged**: no network call is introduced; Telegram transport remains outside.
- **The stage is small**: only warehouse report calculation, page and export preparation move.
- **Evidence is required**: existing value-level tests execute the production component; build verifies packaging.

The Phase 1 design introduces no constitutional exception.

## Project Structure

```text
PrilavokPOS/
├── pos.html
└── Web/js/
    ├── core/storage.js
    └── features/
        ├── web-orders.js
        ├── inventory.js
        └── warehouse-reporting.js

tests/
└── product-stock.test.cjs

specs/019-warehouse-reporting-module/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── results.md
├── contracts/runtime-boundary.md
├── checklists/requirements.md
└── tasks.md
```

**Structure Decision**: Continue the feature-per-domain layout. The existing Xcode folder resource
packages the component without a project-file edit.

## Complexity Tracking

No constitution violations require justification.
