# Feature Specification: runtime фотографий товара

**Roadmap**: R1, R3, R8
**Baseline**: `c0621ed`
**Scope**: выбор, подготовка, native-чтение и удаление локального фото без изменения сохранения товара

## Problem

Runtime фотографий товара остаётся в `pos.html` после выделения editor и persistence boundary.
Код обслуживает native picker на iPad, fallback file input, ограничение размера изображения и
асинхронное чтение локального файла для повторного upload. Его нужно выделить целиком, сохранив
защиту от запоздалых callbacks и текущий local-first контракт.

## User Scenarios

### US1 — актуальный результат выбора отображается в карточке

Выбранное фото применяется только к той сессии редактора, которая открыла picker. Запоздалый native
результат после закрытия или перехода в другую карточку удаляется из локального sandbox.

### US2 — локальное фото доступно для повторного upload

Persistence runtime запрашивает сохранённое native-фото по request ID и получает только связанный
callback. Отсутствующий bridge или timeout возвращает пустой результат, не блокируя сохранение.

### US3 — browser fallback сохраняет ограничение размера

При отсутствии native picker file input уменьшает изображение до существующего JPEG-лимита,
показывает preview и оставляет фактическую запись товара функции `saveProduct`.

## Functional Requirements

- **FR-001**: Native picker MUST bind its callback to the current editor session.
- **FR-002**: Stale native results MUST NOT change the current draft and their local file MUST be removed.
- **FR-003**: Native read requests MUST preserve request-ID correlation and existing timeout behavior.
- **FR-004**: Browser processing MUST preserve the current dimensions, quality attempts and byte limit.
- **FR-005**: Removing a draft photo MUST preserve current flags and native cleanup behavior.
- **FR-006**: Product persistence, JSON, storage keys, upload endpoint and network order MUST not change.
- **FR-007**: Existing global callback names MUST remain available to Swift and editor markup.

## Success Criteria

- **SC-001**: Module load/API test confirms ordering before persistence, editor and startup.
- **SC-002**: Native picker regression proves stale callback cleanup and current-session acceptance.
- **SC-003**: Native read regression proves request/response correlation.
- **SC-004**: Full Node suite, syntax, diagnostics and Simulator build pass.

## Assumptions

- UI, image quality and size policy remain unchanged in this refactoring stage.
- Physical picker and camera/library checks remain in final iPad acceptance.
