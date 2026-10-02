# Feature Specification: модуль категорий товаров

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Automated acceptance complete; device verification deferred

**Input**: User description: "Продолжить постепенную production-ready миграцию после каталога; вынести категории отдельным безопасным этапом."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Категории сохраняют товары и раскладку (Priority: P1)

Администратор создаёт или переименовывает категорию, а товары, плитки и навигация продолжают
ссылаться на правильное имя после сохранения.

**Why this priority**: Несогласованное переименование может скрыть товары в каталоге или рабочей зоне.

**Independent Test**: Создать категорию, затем переименовать существующую с товаром, layout tile и
navigation entry и проверить прежние storage keys.

**Acceptance Scenarios**:

1. **Given** новая категория, **When** она сохранена, **Then** её имя, цвет, обозначение и WEB-флаг записаны в прежний layout.
2. **Given** используемая категория, **When** она переименована, **Then** товары, navigation и category tile получают новое имя.
3. **Given** существующие данные, **When** POS обновлён, **Then** миграция или новые обязательные поля не требуются.

---

### User Story 2 - Удаление и обозначения остаются безопасными (Priority: P2)

Администратор не может удалить категорию с товарами, а обозначение плитки ограничивается тремя
видимыми Unicode-символами.

**Why this priority**: Удаление используемой категории нарушает навигацию, а разрезанный emoji портит UI.

**Independent Test**: Проверить блокировку непустой категории и Unicode grapheme truncation.

**Acceptance Scenarios**:

1. **Given** категория с товаром, **When** запрошено удаление, **Then** подтверждение не открывается и данные не меняются.
2. **Given** emoji sequence, **When** сохраняется обозначение, **Then** остаются максимум три видимых символа.

---

### User Story 3 - Категории изолированы от монолита (Priority: P3)

Разработчик сопровождает category CRUD в отдельном production-компоненте, не перемещая общий delete
confirmation, product editor или рабочую зону.

**Why this priority**: Узкая граница позволяет проверять каждое изменение отдельно.

**Independent Test**: Компонент исполняется общей fixture, загружается до `loadAll()` и является
единственной реализацией category UI API.

**Acceptance Scenarios**:

1. **Given** запуск POS, **When** выполняется первый render, **Then** category API уже доступен.
2. **Given** завершённый этап, **When** проверяется `pos.html`, **Then** в нём нет дубликата функций модуля.

### Edge Cases

- Пустое или дублирующееся имя.
- Переименование без navigation entry или category tile.
- Категория с выключенной WEB-публикацией.
- Пустое обозначение плитки.
- Составной emoji, variation selector и флаг.
- Удаление категории с товарами.
- Категория уже отсутствует к моменту удаления.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Создание и редактирование категории MUST сохранить текущий UI и validation.
- **FR-002**: Переименование MUST обновлять прежние ссылки в products, layout и posNavigation.
- **FR-003**: Используются прежние keys `products`, `layout`, `posNavigation` и JSON-форматы.
- **FR-004**: Цвет, tile symbol и category WEB flag MUST сохранить текущее поведение.
- **FR-005**: Tile symbol MUST оставаться Unicode/grapheme-safe с пределом три символа.
- **FR-006**: Категорию с товарами MUST быть невозможно удалить.
- **FR-007**: Общие `requestDelete`/`confirmDelete`, product deletion, editor и workspace MUST остаться за границей этапа.
- **FR-008**: Сеть, версия и `project.pbxproj` MUST остаться неизменными.
- **FR-009**: Автоматизированные проверки MUST исполнять фактический production-компонент.

### Key Entities

- **Category**: имя в `categoryOrder` и product references.
- **Category presentation**: color, symbol и online flag в layout.
- **Category navigation entry**: имя категории и её folder/product items.
- **Category tile**: layout item `{type: 'category', id}`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Создание и переименование сохраняют ожидаемые legacy keys во всех test scenarios.
- **SC-002**: Непустая категория блокируется до confirmation в 100% тестов.
- **SC-003**: Unicode test сохраняет ровно три целых grapheme при превышении лимита.
- **SC-004**: Полный regression suite и Simulator build проходят.
- **SC-005**: В `pos.html` не остаётся реализации функций модуля.

## Assumptions

- Существующая последовательность нескольких storage writes сохраняется в этом refactor-only этапе.
- Её атомарность требует отдельного safety-среза с rollback/recovery design.
- Физическая проверка модальных окон выполняется в общем финальном прогоне.
