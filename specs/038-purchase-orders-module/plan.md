# Implementation Plan: модуль заказов поставщикам

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Сначала закрепить durable-success и escaping тестами, затем собрать активный purchase-order runtime
в одном classic module. Storage keys, journal, данные и интерфейс остаются прежними.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView  
**Storage**: `prilavok_products`, `prilavok_purchaseOrders`, `prilavok_receivings`,
`prilavok_criticalStorageJournal`  
**Tests**: `node --test tests/*.test.cjs`, `node --check`, iOS Simulator build

## Constitution Check

- Локальные снимки сохраняются до публикации runtime.
- Ключи, prefix и JSON shape не меняются.
- Сеть и автоматическая синхронизация не добавляются.
- Изменение ограничено одним доменом и удаляет только функции без call sites.

## Implementation Order

1. Добавить regression tests pending commit, post-commit UI error и unsafe legacy ID.
2. Создать `purchase-orders.js` с прежним public global API.
3. Разделить commit и presentation result в `finalizePurchaseOrder`.
4. Удалить доказанно неиспользуемые helpers.
5. Прогнать tests, syntax, diagnostics и Simulator build.
6. Обновить architecture, roadmap, audit и results.

