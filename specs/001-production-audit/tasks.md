# Tasks: аудит надёжности M POS

Input: spec.md, plan.md, research.md, data-model.md, contracts/README.md.
[X] означает выполненную задачу аудита, а не исправление runtime.

## Phase 1 — Setup

- [x] T001 Зафиксировать git baseline/рабочие изменения в specs/001-production-audit/results.md.
- [x] T002 Проверить Spec Kit и заполнить .specify/memory/constitution.md существующими принципами.

## Phase 2 — Foundation

- [x] T003 Описать границы/сущности в specs/001-production-audit/data-model.md и contracts/README.md.

## Phase 3 — US1: документация (P1)

Критерий: текущие/будущие/отменённые решения не смешиваются, ссылки разрешаются.

- [x] T004 [US1] Создать навигацию docs/README.md и зафиксировать исходную документацию проекта.
- [x] T005 [US1] Перенести D13 в docs/archive/2026-10-01-delta-history.md и отделить архив от действующих решений.

## Phase 4 — US2: критические операции (P1)

Критерий: результаты автоматических проверок и подтверждённые проблемы имеют доказательства.

- [x] T006 [US2] Выполнить tests/*.test.cjs и backend tests, записать итог в specs/001-production-audit/results.md.
- [x] T007 [US2] Создать и выполнить specs/001-production-audit/diagnostics.cjs без сети и реальных данных.
- [x] T008 [US2] Просмотреть критические записи/checkout/лояльность/печать и записать specs/001-production-audit/findings.md.
- [x] T009 [US2] Добавить fault-injection проверки оплаты, возврата, приёмки и backup; записать результаты в specs/001-production-audit/results.md.
- [x] T010 [US2] Пройти backend checkout/program failpoints, а также проверки последовательности и авторизации лояльности; обновить specs/001-production-audit/findings.md.

## Phase 5 — US3: полная приёмка (P2)

Критерий плана: все разделы имеют шаги и ожидаемый результат. Критерий приёмки: фактический iPad PASS.

- [x] T011 [US3] Подготовить матрицу specs/001-production-audit/cases.md и порядок quickstart.md.
- [x] T012 [US3] Выполнить simulator build PrilavokPOS.xcodeproj, записать specs/001-production-audit/results.md.
- [ ] T013 [US3] Пройти физические S/P/H/C/N/R/U из specs/001-production-audit/cases.md после исправления P0.
- [ ] T014 [US3] Пройти WEB/Telegram/LAN/PDF/XLSX и security/backup из specs/001-production-audit/cases.md в безопасном тестовом окружении.

## Phase 6 — Polish

- [x] T015 Проверить ссылки, diff, неизменность runtime; сохранить specs/001-production-audit/results.md.
- [x] T016 Выполнить read-only Spec Kit analyze и сохранить specs/001-production-audit/analyze.md.

## Dependencies и стратегия

T001–T003 → US1/US2/US3. T006–T010 → исправления отдельными этапами → T013/T014.
T011/T012 не зависят от завершения backend failpoints. T015/T016 после документации и первичного аудита.
Всего 16 задач: setup 2, foundation 1, US1 2, US2 5, US3 4, polish 2; выполнено 14,
физическая и интеграционная приёмка T013/T014 остаётся открытой.
Первый полезный результат: US1 + первичный US2; полная приёмка US3 отдельно, после устранения P0/P1.
Теоретически независимо выполняются проверки ссылок US1, POS/backend тесты US2, сборка/план US3;
автономные агенты здесь не запускались. Изменения одного документа выполнять последовательно.
