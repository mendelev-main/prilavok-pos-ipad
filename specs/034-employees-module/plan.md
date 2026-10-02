# Implementation Plan: сотрудники и локальные права

**Branch**: `main` | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

## Summary

Закрепить storage-first CRUD сотрудников тестами, сохранить действующую модель ролей и удаления, затем перенести функции отображения и управления сотрудниками в отдельный classic module с прежним глобальным API.

## Technical Context

**Language/Version**: JavaScript ES2020 in WKWebView
**Storage**: `prilavok_employees` через общий adapter
**Tests**: `node --test tests/*.test.cjs`, `node --check`, iOS Simulator build

## Constitution Check

- POS остаётся source of truth; операция полностью локальная.
- Ключ и JSON shape не меняются.
- Нет сетевых вызовов и sync triggers.
- Ошибка storage не блокирует запуск и не публикует несохранённые права.
- Извлекается один ограниченный домен; физическая проверка остаётся в финальной iPad-матрице.
