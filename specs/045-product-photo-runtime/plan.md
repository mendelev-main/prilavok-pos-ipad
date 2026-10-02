# Implementation Plan: runtime фотографий товара

## Context

**Runtime**: classic JavaScript in WKWebView
**Native boundary**: `window.webkit.messageHandlers.photoPicker`
**Dependencies**: editor session state, DOM preview, persistence retry read, Swift callbacks

## Constitution Check

- Товар продолжает сохраняться локально через отдельный persistence module.
- Формат `localImageId`/`imageUploadPending` и product JSON не меняется.
- Модуль не выполняет upload и не добавляет сетевых триггеров.
- Этап сохраняет существующий UI и native callback names.

## Design

Создать `Web/js/features/product-photo.js` с picker, native accept/read callbacks, browser resize и
draft removal. Подключить после product configuration и до product persistence. `saveProduct` и
upload оставить в `product-persistence.js`.

## Validation

Расширить fixture и добавить module boundary, stale callback и correlated read regressions. Затем
выполнить full Node, syntax, historical diagnostics, unsigned Simulator build и source/bundle hash.
