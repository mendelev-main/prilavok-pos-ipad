# Implementation Plan: полный production-аудит iPad-приложения

**Branch**: `main` | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

## Summary

Провести статический и динамический аудит всего iPad runtime без обращения к production-сервисам.
Сначала проверить сохранность финансовых и складских операций, затем lifecycle/native bridge,
печать, отчёты, сеть и UI-state. Зафиксировать только доказанные выводы.

## Constitution Check

- Аудит не запускает синхронизацию и не меняет production-данные.
- Форматы storage и версия приложения остаются без изменений.
- Автоматические проверки не заменяют физический iPad, LAN-принтер и реальные lifecycle-события.
- Исправления P0/P1 выполняются отдельными малыми спецификациями.

## Methods

1. Inventory подключённых файлов и entry points из Xcode project и HTML scripts.
2. Data-flow review для критических операций и failure paths.
3. Static searches: ignored errors, unbounded timers/network, unsafe parsing, duplicate actions,
   direct storage bypasses, lifecycle/threading and force unwraps.
4. Existing Node tests и дополнительные read-only diagnostic harnesses на синтетических данных.
5. Simulator build без signing.
6. Findings, coverage matrix и физический acceptance checklist.
