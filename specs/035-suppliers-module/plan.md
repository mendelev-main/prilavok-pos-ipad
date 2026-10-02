# Implementation Plan: поставщики

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Закрепить storage-first CRUD поставщиков тестами и перенести UI handlers в отдельный classic module. Черновики заказа и приёмки остаются отдельным следующим срезом.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Storage**: `prilavok_suppliers` через общий adapter
**Tests**: `node --test tests/*.test.cjs`, `node --check`, iOS Simulator build

## Constitution Check

- POS и его локальный справочник остаются source of truth.
- Ключ и JSON shape не меняются.
- Сеть и sync triggers не добавляются.
- Сбой storage не публикует несохранённые изменения.
- Извлекается только CRUD поставщиков; проведение закупок и приёмки не переносится.
