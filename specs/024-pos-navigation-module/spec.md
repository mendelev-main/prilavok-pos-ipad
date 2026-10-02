# Feature Specification: модуль навигации рабочей зоны

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Automated acceptance complete; device verification deferred

**Input**: Продолжить постепенную production-ready миграцию и вынести рабочую зону, папки и раскладку плиток отдельным безопасным этапом.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Папки сохраняют локальную навигацию (Priority: P1)

Администратор создаёт, переименовывает и удаляет папки, переносит товары и после перезапуска видит ту же структуру без изменения товаров и остатков.

**Independent Test**: Изменить папку и расположение товаров, перезапустить fixture с тем же storage и проверить `posNavigation`.

**Acceptance Scenarios**:

1. Создание, переименование, перемещение и удаление используют прежний ключ и формат.
2. Удаление папки возвращает её товары в корень категории.
3. Ошибка записи оставляет текущее состояние и каталог без изменений.

### User Story 2 - Плитки сохраняют прежнее поведение (Priority: P2)

Кассир открывает категории и папки, добавляет товар в чек, а администратор меняет состав и положение плиток прежними действиями.

**Independent Test**: Проверить click routing, scoped ordering, drag/drop и cancel.

**Acceptance Scenarios**:

1. Folder click открывает папку, product click добавляет товар в чек.
2. Сортировка внутри папки не меняет другие уровни.
3. Отмена drag не записывает layout.

### User Story 3 - Runtime изолирован от монолита (Priority: P3)

Разработчик сопровождает навигацию в отдельном production-компоненте, сохраняя глобальный API и порядок загрузки.

**Independent Test**: Компонент исполняется fixture и загружается до `loadAll()`.

### Edge Cases

- Старый, пустой или повреждённый `posNavigation`.
- Удалённый товар, дубли и ссылка на отсутствующую папку.
- Пустая рабочая зона и лимит 20 плиток.
- Pointer cancel и занятая grid-cell.
- Папка с нулём, двумя и более четырёх товаров.
- Ошибка local storage.

## Requirements *(mandatory)*

- **FR-001**: Сохранить ключи `posNavigation` и `layout`, prefix и JSON-форматы.
- **FR-002**: Сохранить normalization и восстановление старых данных без миграции.
- **FR-003**: Сохранить UI, inline handlers, global API и поведение папок/плиток.
- **FR-004**: Не менять товары, остатки, корзину, оплату и сетевую логику.
- **FR-005**: Ошибка storage не должна повреждать in-memory navigation.
- **FR-006**: `productCategoryKey` и cart runtime остаются за границей этапа.
- **FR-007**: Production-компонент должен исполняться автоматизированными тестами.
- **FR-008**: Версия и `project.pbxproj` остаются неизменными.

## Success Criteria *(mandatory)*

- **SC-001**: Все существующие navigation regressions проходят на production-компоненте.
- **SC-002**: Новый load-order/API contract test проходит.
- **SC-003**: Полный Node suite и Simulator build проходят.
- **SC-004**: Перенесённая реализация совпадает с baseline побайтно.
- **SC-005**: В `pos.html` не остаётся дубликата функций модуля.
