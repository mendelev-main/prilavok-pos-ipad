# Tasks: модуль инвентаризации

**Input**: Design documents from `/specs/018-inventory-module/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Phase 1: Setup

**Purpose**: Зафиксировать совместимую границу домена.

- [X] T001 Создать полный Spec Kit-комплект в `specs/018-inventory-module/`
- [X] T002 Зафиксировать persisted и runtime контракты в `specs/018-inventory-module/data-model.md` и `specs/018-inventory-module/contracts/runtime-boundary.md`

---

## Phase 2: Foundational

**Purpose**: Подготовить подключение production-компонента до запуска POS.

- [X] T003 [US3] Создать `PrilavokPOS/Web/js/features/inventory.js`
- [X] T004 [US3] Подключить `inventory.js` до `loadAll()` в `PrilavokPOS/pos.html`
- [X] T005 [US3] Исполнять production-компонент в fixture `tests/product-stock.test.cjs`

**Checkpoint**: Прежний глобальный API доступен до первой отрисовки.

---

## Phase 3: User Story 1 — Сохранность остатков (Priority: P1)

**Goal**: Сохранить атомарную фиксацию и завершение инвентаризации.

**Independent Test**: Failure, successful commit и restart recovery сценарии проходят с production-файлом.

- [X] T006 [US1] Перенести draft/fix/complete runtime без изменения поведения в `PrilavokPOS/Web/js/features/inventory.js`
- [X] T007 [US1] Проверить existing atomicity/recovery tests через `tests/product-stock.test.cjs`
- [X] T008 [US1] Подтвердить неизменность journal operation names и storage keys поиском production-кода

---

## Phase 4: User Story 2 — Неизменный интерфейс и расписание (Priority: P2)

**Goal**: Сохранить график, напоминание, настройки, поиск, рабочий экран и сводку.

**Independent Test**: UI helper tests и полный regression suite проходят без изменения результатов.

- [X] T009 [US2] Перенести scheduling, summary и render runtime в `PrilavokPOS/Web/js/features/inventory.js`
- [X] T010 [US2] Добавить load-order/public API contract test в `tests/product-stock.test.cjs`
- [X] T011 [US2] Прогнать полный Node-набор `tests/*.test.cjs`

---

## Phase 5: User Story 3 — Изолированная зона изменений (Priority: P3)

**Goal**: В `pos.html` не остаётся реализации инвентаризации, а component входит в app bundle.

**Independent Test**: Поиск находит одну production-реализацию, syntax checks и Xcode build проходят.

- [X] T012 [US3] Проверить отсутствие дубликатов функций в `PrilavokPOS/pos.html`
- [X] T013 [US3] Выполнить syntax checks для `PrilavokPOS/Web/js/features/inventory.js` и тестовой fixture
- [X] T014 [US3] Собрать iOS Simulator и проверить `Web/js/features/inventory.js` внутри `.app`

---

## Phase 6: Documentation and evidence

- [X] T015 [P] Обновить `docs/ARCHITECTURE.md` и `ROADMAP.md`
- [X] T016 Зафиксировать проверку в `specs/018-inventory-module/quickstart.md` и `specs/018-inventory-module/results.md`
- [X] T017 Проверить итоговый diff, отсутствие изменения версии/проекта и отметить задачи в `specs/018-inventory-module/tasks.md`

## Dependencies & Execution Order

- T003–T005 задают runtime-порядок.
- T006–T011 подтверждают поведение и данные.
- T012–T014 выполняются после полного Node PASS.
- T015–T017 закрывают доказательства этапа.
- Физическая приёмка остаётся в общем финальном ручном прогоне.
