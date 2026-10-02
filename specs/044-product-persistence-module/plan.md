# Implementation Plan: модуль сохранения товара

## Context

**Runtime**: classic JavaScript in WKWebView
**Storage**: `PrilavokCore.Storage.set('products', ...)`
**Dependencies**: product configuration, editor shell, photo read callback, catalog, role helpers

## Constitution Check

- POS остаётся source of truth; publish в `state.products` происходит только после durable write.
- JSON и ключ `prilavok_products` не меняются.
- Upload остаётся необязательной операцией после локального commit.
- Новые sync triggers и сетевые вызовы не добавляются.
- Этап является механическим выделением одной существующей границы.

## Design

Создать `Web/js/features/product-persistence.js` с существующими global functions:
`productDependsOn`, `saveProduct`, `canEditProductWebSetting`, `toggleProductOnline` и
`toggleProductModalOnline`. Подключить модуль после product configuration и до product editor.
Photo picker/compression/read functions и delete facade оставить inline.

## Validation

Сначала расширить fixture и module-boundary assertions, затем выполнить весь Node suite,
production JavaScript syntax checks, historical diagnostics, unsigned Simulator build и проверку
совпадения source/bundle SHA-256.
