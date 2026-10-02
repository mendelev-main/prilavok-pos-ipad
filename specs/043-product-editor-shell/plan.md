# Implementation Plan: оболочка редактора товара

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Перенести editor shell в `Web/js/features/product-editor.js`, сохранить global API и исправить
сериализацию product ID в действиях таблицы товаров.

## Technical Context

**Runtime**: classic JavaScript in WKWebView
**Storage**: модуль не пишет данные напрямую
**Dependencies**: product configuration, catalog, `saveProduct`, photo callbacks, modal helpers
**Tests**: Node, syntax, audit diagnostics, iOS Simulator build

## Constitution Check

- Storage keys и product JSON не меняются.
- Save/photo/network boundaries остаются inline и без изменений.
- UI переносится дословно; функциональная поправка ограничена безопасными arguments.
- Изменение выполняется отдельным проверяемым этапом.

## Implementation Order

1. Добавить module/API и catalog action regressions.
2. Создать `Web/js/features/product-editor.js` и подключить после product configuration.
3. Удалить перенесённый inline block.
4. Выполнить полную матрицу и обновить документацию.
