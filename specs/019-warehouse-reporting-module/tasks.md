# Tasks: модуль складской аналитики

**Input**: Design documents from `/specs/019-warehouse-reporting-module/`

## Phase 1: Setup

- [X] T001 Создать полный Spec Kit-комплект в `specs/019-warehouse-reporting-module/`
- [X] T002 Зафиксировать read-only и native payload контракты в `specs/019-warehouse-reporting-module/contracts/runtime-boundary.md`

## Phase 2: Foundational

- [X] T003 [US3] Создать `PrilavokPOS/Web/js/features/warehouse-reporting.js`
- [X] T004 [US3] Подключить компонент до `loadAll()` в `PrilavokPOS/pos.html`
- [X] T005 [US3] Исполнять production-компонент в `tests/product-stock.test.cjs`

## Phase 3: User Story 1 — неизменные расчёты (Priority: P1)

**Independent Test**: value-level и legacy warehouse tests проходят без storage writes.

- [X] T006 [US1] Перенести расчёт и форматирование без изменения поведения в `PrilavokPOS/Web/js/features/warehouse-reporting.js`
- [X] T007 [US1] Проверить существующие расчётные и legacy tests через production-файл
- [X] T008 [US1] Подтвердить read-only поведение полным Node-набором

## Phase 4: User Story 2 — совместимый PDF/XLSX export (Priority: P2)

**Independent Test**: пять секций и оба native action сохраняют прежний payload.

- [X] T009 [US2] Перенести страницу и export actions в `PrilavokPOS/Web/js/features/warehouse-reporting.js`
- [X] T010 [US2] Проверить selected-section, numeric Excel и authorization tests
- [X] T011 [US2] Подтвердить, что Telegram transport использует прежний публичный payload API

## Phase 5: User Story 3 — изолированный компонент (Priority: P3)

- [X] T012 [US3] Добавить load-order/public API contract test в `tests/product-stock.test.cjs`
- [X] T013 [US3] Проверить отсутствие дубликата в `PrilavokPOS/pos.html` и выполнить syntax checks
- [X] T014 [US3] Собрать Simulator и проверить компонент внутри `.app`

## Phase 6: Documentation and evidence

- [X] T015 [P] Обновить `docs/ARCHITECTURE.md` и `ROADMAP.md`
- [X] T016 Зафиксировать результаты в `specs/019-warehouse-reporting-module/quickstart.md` и `results.md`
- [X] T017 Проверить diff, версию и Xcode project; отметить выполненные задачи

## Dependencies & Execution Order

T003–T005 → T006–T011 → T012–T014 → T015–T017. Физическая приёмка остаётся в общем финальном прогоне.
