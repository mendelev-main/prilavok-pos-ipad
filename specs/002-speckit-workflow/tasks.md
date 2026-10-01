# Tasks: единый workflow GitHub Spec Kit

**Input**: [spec.md](spec.md), [plan.md](plan.md)

## Phase 1 — Specify and plan

- [x] T001 Сверить актуальную официальную документацию GitHub Spec Kit.
- [x] T002 Проверить installed Codex integration через `specify integration status`.
- [x] T003 Сравнить MASTER/DELTA/LOYALTY с constitution, roadmap и feature artifacts.

## Phase 2 — Migrate active documentation

- [x] T004 [US1] Создать `ROADMAP.md` и перенести только открытые направления.
- [x] T005 [US2] Создать `docs/ARCHITECTURE.md` из актуальных фактов MASTER.
- [x] T006 [US1] Обновить `docs/README.md` под единый lifecycle.
- [x] T007 [US1] Обновить constitution и audit artifacts, которые ссылаются на старую схему.
- [x] T008 [US1] Удалить корневые `MASTER_SPEC.md`, `DELTA_SPEC.md`, `LOYALTY_SPEC.md`.

## Phase 3 — Converge and verify

- [x] T009 Отметить фактически закрытые T009/T010 в audit tasks; оставить physical acceptance открытой.
- [x] T010 Проверить все активные Markdown-ссылки, отсутствие stale root-spec references и `git diff --check`.
- [x] T011 Повторить `specify integration status` и записать итог в `results.md`.
