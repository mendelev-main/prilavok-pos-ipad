# Implementation Plan: безопасное завершение приёмки

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Закрыть найденную concurrency-границу общим critical guard и вынести чистые расчёты и проведение
приёмки в отдельный classic module. Сохранить существующий journal, форматы и UI.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView  
**Storage**: `prilavok_products`, `prilavok_purchaseOrders`, `prilavok_receivings`,
`prilavok_receivingDraft`, `prilavok_criticalStorageJournal`  
**Tests**: `node --test tests/*.test.cjs`, `node --check`, iOS Simulator build

## Constitution Check

- Локальный POS остаётся source of truth; сеть не участвует.
- Ключи и JSON shape не меняются.
- Все связанные снимки проходят существующий recoverable journal.
- Runtime публикуется только после устойчивой записи.
- Изменение ограничено одним доменным boundary.

## Implementation Order

1. Добавить regression tests общего guard и storage-first публикации.
2. Вынести completion functions в `Web/js/features/receiving.js`.
3. Добавить `criticalOperationBusy` вокруг commit с release в `finally`.
4. Прогнать тесты, syntax, diagnostics и Simulator build.
5. Обновить architecture, roadmap, audit и results.

