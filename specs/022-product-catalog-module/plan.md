# Implementation Plan: модуль каталога товаров

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Вынести CSV parsing/planning/confirmation, поиск, сортировку и render таблицы товаров из `pos.html`
в отдельный классический компонент. Сохранить прежний global API, local-first import и UI, подключить
production-файл к общей test fixture и оставить product editor/categories отдельными доменами.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Primary Dependencies**: UIKit, WKWebView, existing storage adapter and DOM/product runtime
**Storage**: Existing `products` localStorage record
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target Platform**: iPadOS 16+
**Project Type**: Native iPad shell with embedded local web application
**Performance Goals**: No additional writes, network calls or full renders during live search
**Constraints**: Exact data/UI compatibility; additive import; no version or Xcode project change
**Scale/Scope**: One contiguous catalog block of about 180 lines

## Constitution Check

*GATE: passed before research and re-checked after design.*

- Local catalog remains authoritative and is written before runtime publication.
- Existing `products` key, prefix and JSON shape remain unchanged.
- No network path or sync trigger is introduced.
- One coherent domain moves; editor, recipes, categories, workspace and checkout stay in place.
- Existing direct tests and a load-order test execute the production component.

## Project Structure

```text
PrilavokPOS/Web/js/features/
├── analytics.js
├── product-catalog.js
└── ...

PrilavokPOS/pos.html
tests/product-stock.test.cjs
specs/022-product-catalog-module/
```

**Structure Decision**: Continue feature-per-domain classic scripts while inline handlers remain.

## Complexity Tracking

No constitution violations require justification.
