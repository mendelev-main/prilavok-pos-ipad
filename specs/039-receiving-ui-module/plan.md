# Implementation Plan: модуль интерфейса приёмки

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Добавить escaping regression test, перенести активный экран/редактор/историю в один classic
module и удалить две старые функции без call sites.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView  
**Storage**: без изменений  
**Dependencies**: `purchase-orders.js`, `receiving-drafts.js`, `receiving.js`  
**Tests**: `node --test tests/*.test.cjs`, `node --check`, iOS Simulator build

## Constitution Check

- Локальные данные и storage format не меняются.
- Сеть и sync не затрагиваются.
- Изменение ограничено presentation/editor boundary.
- Удаляются только функции без call sites.

## Implementation Order

1. Добавить module/dead-helper and imported quantity tests.
2. Создать `receiving-ui.js` с прежним global API.
3. Экранировать отображаемое количество как текст.
4. Удалить старый inline runtime и подключить module.
5. Прогнать tests, syntax, diagnostics and Simulator build.
6. Обновить architecture, roadmap, audit and results.

