# Implementation Plan: модуль резервных копий

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Закрепить строгую проверку присутствующих коллекций, перенести backup boundary в classic script и
сохранить существующий global API, schema v12 и critical journal.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView  
**Storage**: прежние logical keys через storage adapter и critical journal  
**Dependencies**: navigation normalization, current-order snapshot, payment draft validation,
printer settings adapter  
**Tests**: Node, `node --check`, audit diagnostics, iOS Simulator build

## Constitution Check

- Формат и ключи не меняются.
- Корректные старые backup сохраняют прежние defaults.
- Повреждённый файл отклоняется до записи.
- Сеть и синхронизация не затрагиваются.

## Implementation Order

1. Добавить module/API и malformed optional collection regression tests.
2. Создать `Web/js/features/backup.js` с прежним global API.
3. Отличать отсутствующий optional section от присутствующего неверного типа.
4. Удалить inline backup block и подключить module до `loadAll()`.
5. Выполнить полный набор проверок и обновить документацию.

