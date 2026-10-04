# Tasks: модуль WEB-заказов

**Input**: Design documents from `/specs/017-web-orders-module/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Phase 1: Setup

**Purpose**: Зафиксировать границу первого архитектурного среза.

- [X] T001 Создать каталог и полный комплект Spec Kit-документов в `specs/017-web-orders-module/`
- [X] T002 Зафиксировать runtime, storage и network контракты в `specs/017-web-orders-module/contracts/runtime-boundary.md`

---

## Phase 2: Foundational

**Purpose**: Подготовить безопасную загрузку отдельного компонента без изменения startup-поведения.

- [X] T003 [US2] Создать feature-каталог и production-файл `PrilavokPOS/Web/js/features/web-orders.js`
- [X] T004 [US2] Подключить feature-компонент до `loadAll()` в `PrilavokPOS/pos.html`

**Checkpoint**: Production runtime видит прежний глобальный API до начала загрузки данных.

---

## Phase 3: User Story 1 — WEB-заказы работают без изменений (Priority: P1)

**Goal**: Сохранить local-first принятие, retry/recovery, UI и сетевой контракт.

**Independent Test**: Существующие WEB-тесты исполняют production-компонент и подтверждают одну
локальную копию заказа при повторах и сбоях backend.

- [X] T005 [US1] Перенести существующий WEB-orders runtime без изменения поведения в `PrilavokPOS/Web/js/features/web-orders.js`
- [X] T006 [US1] Исполнять production-компонент в fixture `tests/product-stock.test.cjs`
- [X] T007 [US1] Добавить проверку порядка script-подключения и публичного API в `tests/product-stock.test.cjs`
- [X] T008 [US1] Прогнать WEB-сценарии и весь Node-набор из `tests/*.test.cjs`

**Checkpoint**: WEB-заказы проходят существующие и boundary-проверки.

---

## Phase 4: User Story 2 — Изолированная зона изменений (Priority: P2)

**Goal**: Изменения WEB-заказов находятся в отдельном компоненте, а `pos.html` не содержит их реализацию.

**Independent Test**: Поиск подтверждает единственную production-реализацию в feature-файле; Xcode
упаковывает её через существующий ресурс `Web`.

- [X] T009 [US2] Проверить отсутствие дубликата WEB-orders реализации в `PrilavokPOS/pos.html`
- [X] T010 [US2] Выполнить syntax checks для `PrilavokPOS/Web/js/features/web-orders.js` и `tests/product-stock.test.cjs`
- [X] T011 [US2] Выполнить simulator build без изменения `PrilavokPOS.xcodeproj/project.pbxproj`

**Checkpoint**: Компонент изолирован и входит в приложение без конфигурационных изменений.

---

## Phase 5: Documentation and evidence

**Purpose**: Зафиксировать результат этапа и следующий архитектурный шаг.

- [X] T012 [P] Обновить архитектурную карту компонента в `docs/ARCHITECTURE.md`
- [X] T013 [P] Обновить состояние R8 в `ROADMAP.md`
- [X] T014 Зафиксировать результаты автоматической проверки в `specs/017-web-orders-module/quickstart.md`
- [X] T015 Проверить итоговый diff, отсутствие изменения версии/данных и отметить выполненные задачи в `specs/017-web-orders-module/tasks.md`

## Dependencies & Execution Order

- T003 → T004 → T005 задают runtime-порядок и перенос реализации.
- T006–T008 зависят от T005.
- T009–T011 зависят от успешного полного тестового набора.
- T012–T015 выполняются после подтверждённой реализации.
- Ручная проверка на физическом iPad остаётся в общем финальном прогоне по решению пользователя.

## Follow-up: личное Telegram-уведомление о WEB-заказе

- [X] T016 Добавить совместимые поля ID рабочего устройства и флага уведомлений в настройки Telegram
- [X] T017 Регистрировать ID и флаг на backend только после локального сохранения настроек
- [X] T018 Перенести отправку с POS SSE на backend после атомарного создания заказа
- [X] T019 Исключить повторную отправку для идемпотентного результата checkout
- [X] T020 Закрепить локальную совместимость и backend-контракт автоматизированными проверками
