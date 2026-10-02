# Implementation Plan: устойчивые черновики приёмки

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Построить черновик отдельно, сохранить снимок заказа до публикации и закрывать страницу только после подтверждённой записи. Вынести open/save boundary в отдельный classic module.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Storage**: `prilavok_purchaseOrders`, `prilavok_receivingDraft`
**Tests**: `node --test tests/*.test.cjs`, `node --check`, iOS Simulator build

## Constitution Check

- POS и локальный черновик остаются source of truth.
- Ключи и JSON shape не меняются.
- Запись завершается до публикации state и закрытия UI.
- Сеть и sync triggers отсутствуют.
- Проведение приёмки и расчёт себестоимости остаются в существующем critical journal.
