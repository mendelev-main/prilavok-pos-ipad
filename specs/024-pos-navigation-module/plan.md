# Implementation Plan: модуль навигации рабочей зоны

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Вынести contiguous runtime от normalization папок до поиска/drag-and-drop в классический feature script. Сохранить `productCategoryKey` и cart runtime в `pos.html`, прежние storage writes и global API.

## Technical Context

**Language/Version**: Swift 5, HTML/CSS, JavaScript ES2020
**Dependencies**: existing state, storage adapter, catalog/cart/modal helpers
**Storage**: existing `posNavigation` and `layout` records
**Testing**: Node.js 22 `node:test`; Xcode simulator build
**Target**: iPadOS 16+
**Constraints**: exact behavior/data/UI compatibility; no network/version/project change

## Constitution Check

- POS remains authoritative and offline-first.
- Existing keys and shapes remain unchanged.
- No network or sync trigger is introduced.
- One domain is moved without algorithm rewrite.
- Production script is packaged and directly exercised by tests.

## Structure

`PrilavokPOS/Web/js/features/pos-navigation.js` owns workspace folders, visible tiles, layout editor, drag/drop and workspace search. Shared category key and cart remain inline.
