# Implementation Plan: аудит надёжности M POS

**Branch**: main (по решению пользователя) | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)
Spec Kit feature directory: specs/001-production-audit; имя каталога не создаёт git-ветку.

## Summary

Сверить документы с кодом, архивировать отменённые решения, построить матрицу и пройти доступные
автоматические проверки. Воспроизвести критические отказы только на искусственных данных.
Исправления runtime и физическая приёмка — отдельные следующие этапы.

## Technical Context

Swift/UIKit/Network/WKWebView; HTML/CSS/JavaScript в PrilavokPOS/pos.html;
localStorage через Web/js/core/storage.js. Backend: Node/Express, PostgreSQL через Supabase.
Тестирование: node:test + VM, xcodebuild iphonesimulator. Цель: существующий единственный iPad.
Нет нового SLA или изменения модели хранения. Приоритет: сохранность данных и отсутствие блокировки кассы сетью.

## Constitution Check

До/после: аудит сохраняет offline-first и совместимость, не вызывает sync, не пишет в backend,
не меняет runtime и версию. Физические проверки не заменяются сборкой.
Известные нарушения существующего runtime записываются в findings.md, а не скрываются как PASS.

## Project Structure

- MASTER_SPEC.md, DELTA_SPEC.md, LOYALTY_SPEC.md — продуктовые документы.
- docs/README.md — навигация; docs/archive/ — исторические решения.
- specs/001-production-audit/ — spec, plan, tasks, research, data-model, contracts,
  quickstart, cases, findings, results, analyze и diagnostics.cjs.
- PrilavokPOS/pos.html — основной runtime; Web/js/core/storage.js — storage adapter.
- PrilavokPOS/*.swift, Reports/ — native bridges, печать, PDF/XLSX.
- tests/*.test.cjs — существующая POS-регрессия.
- Backend проверяется в отдельном checkout, указанном в results.md.

## Этапы и критерии перехода

0. Research: inventory, git status, реальные контракты и baseline → research.md.
1. Design: сущности и границы контрактов → data-model.md, contracts/README.md.
2. US1: документация и архив; проверить ссылки и противоречия.
3. US2: тесты, сборка, сбои storage/loyalty, обзор backend; результаты → findings/results.
4. US3: последовательная физическая матрица → cases.md, quickstart.md.
5. Read-only analyze: прослеживаемость требований к задачам; никаких правок во время анализа.

## Риски и стратегия

Зелёные VM-тесты не доказывают отсутствие iOS lifecycle/race/UI ошибок.
Полный fault-injection для всех записей, live-сеть, Telegram, принтер и восстановление backup
остаются открытыми. Сначала устранить F01, затем F02/F04/F05/F06/F07; новая функциональность заморожена.
Не объединять исправления разных финансовых механизмов одним рефакторингом.
