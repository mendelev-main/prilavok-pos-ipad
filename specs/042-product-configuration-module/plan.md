# Implementation Plan: модуль конфигурации товара

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Выделить unit/recipe/modifier runtime в один classic script, сохранить глобальный контракт и безопасно
сериализовать product ID в редакторе и модальном выборе модификаторов заказа.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView  
**Storage**: прежний `products`; новых записей модуль не создаёт  
**Dependencies**: product helpers, purchase unit renderer, editor shell, cart composition  
**Tests**: Node, syntax, audit diagnostics, iOS Simulator build

## Constitution Check

- Локальные данные и offline behavior не меняются.
- Storage keys, product JSON, сеть и sync triggers не меняются.
- Сохранение товара и фото не переносятся в этом этапе.
- Изменение ограничено одной связанной областью и проверяется существующей матрицей.

## Implementation Order

1. Добавить module/API и hostile-compatible inline action regressions.
2. Создать `Web/js/features/product-configuration.js`.
3. Подключить модуль до feature consumers и удалить перенесённые inline blocks.
4. Перевести fixture на новый module source без изменения бизнес-ожиданий.
5. Выполнить полную проверку и обновить architecture, roadmap и audit finding.
