# Implementation Plan: модуль WEB-заказов

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/017-web-orders-module/spec.md`

## Summary

Вынести существующий домен WEB-заказов из монолитного `pos.html` в отдельный классический
JavaScript-компонент. Сохранить публичные глобальные функции, storage-ключи, JSON-контракты,
endpoint и порядок local-first принятия. Перенести вызов `loadAll()` после загрузки компонента и
подключить реальный файл компонента к существующим Node-тестам.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Primary Dependencies**: UIKit, WebKit/WKWebView, `PrilavokCore.Storage`, browser `EventSource` and `fetch`
**Storage**: localStorage through the existing adapter with prefix `prilavok_`
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target Platform**: iPadOS 16+
**Project Type**: Native iPad shell with an embedded local web application
**Performance Goals**: No new network requests, timers, or startup waits; synchronous local script loading
**Constraints**: Offline-first; exact UI/data/network compatibility; no version or `project.pbxproj` change; one domain per stage
**Scale/Scope**: One contiguous WEB-orders domain (about 170 lines) and its existing automated scenarios

## Constitution Check

*GATE: passed before research and re-checked after design.*

- **Local POS remains source of truth**: acceptance still persists the parked order and journal before ACK.
- **Compatibility is preserved**: no key, prefix, JSON field, endpoint, or migration changes.
- **Network boundaries stay bounded**: existing EventSource and ACK/retry are moved unchanged; no catalog sync is added.
- **The stage is small**: only WEB-order functions move; payment, products, shifts, printing, and shared storage remain in place.
- **Evidence is required**: tests execute the extracted file and the simulator build validates resource packaging.

The Phase 1 design introduces no constitutional exception.

## Project Structure

### Documentation (this feature)

```text
specs/017-web-orders-module/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
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
    └── features/web-orders.js

tests/
└── product-stock.test.cjs
```

**Structure Decision**: Keep the existing embedded-web structure and add the first feature component
under `Web/js/features/`. The complete `Web` directory is already an Xcode resource, so adding the file
does not require a project-file edit.

## Complexity Tracking

No constitution violations require justification.
