# Implementation Plan: модуль клиентов и лояльности

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Перенести customer/loyalty runtime в один classic script, безопасно сериализовать аргументы inline
actions и удалить две функции старого интерфейса без call sites.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView  
**Storage**: прежние `orders` и `currentOrderSession`  
**Network**: существующие customer/loyalty endpoints с timeout  
**Dependencies**: shifts, render/modal helpers, payment, receipts, parked orders, analytics  
**Tests**: Node, syntax, audit diagnostics, iOS Simulator build

## Constitution Check

- Локальная оплата и offline behavior не меняются.
- Сетевые endpoint/payload/retry не меняются.
- Storage keys и JSON не меняются.
- Изменение ограничено одним связанным доменом.

## Implementation Order

1. Обновить loyalty tests для отдельного module source.
2. Добавить module/API, safe inline arguments и dead-function assertions.
3. Создать `Web/js/features/loyalty.js` и подключить до dependent modules.
4. Удалить два inline loyalty blocks и legacy functions.
5. Выполнить полный набор проверок и обновить документацию.

