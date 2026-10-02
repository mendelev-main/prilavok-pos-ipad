# Implementation Plan: модуль категорий товаров

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Вынести category modal, create/rename, presentation toggles, Unicode tile-symbol helper и guarded
category delete request из `pos.html` в отдельный классический компонент. Сохранить прежние keys,
UI/global API и multi-write sequence; добавить прямые compatibility tests.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Primary Dependencies**: UIKit, WKWebView, existing storage/modal/navigation/product runtime
**Storage**: Existing `products`, `layout` and `posNavigation` records
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target Platform**: iPadOS 16+
**Project Type**: Native iPad shell with embedded local web application
**Performance Goals**: No additional writes, renders or network operations
**Constraints**: Exact UI/data compatibility; no version or Xcode project change
**Scale/Scope**: One contiguous category block of about 130 lines

## Constitution Check

*GATE: passed before research and re-checked after design.*

- POS remains authoritative for categories and referenced products/layout.
- Existing keys and JSON structures remain unchanged.
- No network or sync trigger is introduced.
- Shared deletion, product editor and workspace stay outside the component.
- Tests cover storage compatibility and production component packaging.

## Project Structure

```text
PrilavokPOS/Web/js/features/
├── product-catalog.js
├── product-categories.js
└── ...

PrilavokPOS/pos.html
tests/product-stock.test.cjs
specs/023-product-categories-module/
```

**Structure Decision**: Continue feature-per-domain classic scripts while inline handlers remain.

## Complexity Tracking

The existing rename path writes multiple keys without one critical journal. This stage preserves that
behavior; atomicity is documented for a future safety specification instead of silently changing it.
