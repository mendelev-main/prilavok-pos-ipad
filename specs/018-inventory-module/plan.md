# Implementation Plan: модуль инвентаризации

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/018-inventory-module/spec.md`

## Summary

Вынести существующий домен инвентаризации из `pos.html` в отдельный классический JavaScript-компонент.
Сохранить глобальные UI-действия, storage-схемы, critical journal и порядок применения runtime-состояния.
Подключить компонент до `loadAll()` и исполнять фактический production-файл в полном Node-наборе.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Primary Dependencies**: UIKit, WebKit/WKWebView, `PrilavokCore.Storage`, existing critical storage journal
**Storage**: localStorage through the existing adapter with prefix `prilavok_`
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target Platform**: iPadOS 16+
**Project Type**: Native iPad shell with an embedded local web application
**Performance Goals**: No additional startup waits, storage writes, timers, or network operations
**Constraints**: Offline-first; exact UI/data behavior; no migration, version, or `project.pbxproj` change
**Scale/Scope**: One contiguous inventory domain of about 150 lines and its existing regression scenarios

## Constitution Check

*GATE: passed before research and re-checked after design.*

- **Local POS remains source of truth**: inventory continues to read and write only local state.
- **Compatibility is preserved**: keys, prefix, JSON records, backup fields, and critical journal types are unchanged.
- **Network boundaries stay unchanged**: the component adds no network path or trigger.
- **The stage is small**: only inventory scheduling, draft, fixing, completion, summary, and screens move.
- **Evidence is required**: tests execute the extracted component and the simulator build verifies packaging.

The Phase 1 design introduces no constitutional exception.

## Project Structure

### Documentation (this feature)

```text
specs/018-inventory-module/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── results.md
├── contracts/
│   └── runtime-boundary.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
PrilavokPOS/
├── pos.html
└── Web/js/
    ├── core/storage.js
    └── features/
        ├── web-orders.js
        └── inventory.js

tests/
└── product-stock.test.cjs
```

**Structure Decision**: Continue the feature-per-domain layout under `Web/js/features/`. The `Web`
directory is already copied as a resource, so the new component needs no Xcode project edit.

## Complexity Tracking

No constitution violations require justification.
