# Feature Specification: модуль формирования корзины

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Automated acceptance complete; device verification deferred

**Input**: Продолжить модульную миграцию: выделить добавление, модификаторы, количество и удаление, не затрагивая парковку и оплату.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Товар безопасно добавляется в заказ (Priority: P1)

Кассир добавляет обычный товар, товар с ручной ценой или модификаторами; строка создаётся или объединяется по прежним правилам только при достаточном остатке.

**Independent Test**: Existing modifier/stock tests и новый manual-price contract выполняются production-компонентом.

### User Story 2 - Количество и удаление сохраняют текущую сессию (Priority: P1)

Кассир меняет количество или удаляет строку; проверка остатков выполняется до изменения, а пустая корзина очищает контекст заказа прежним способом.

**Independent Test**: Existing quantity/removal/session regressions проходят без изменения.

### User Story 3 - Строка корзины открывается без touch-жеста (Priority: P2)

Клик или клавиатурное действие открывает редактор позиции даже если ранее не было touchstart.

**Independent Test**: Вызвать handler в свежем runtime и убедиться, что нет `ReferenceError`.

### User Story 4 - Парковка и оплата остаются изолированы (Priority: P1)

Критические операции парковки, оплаты, проведения чека, списания и печати остаются в основном runtime.

**Independent Test**: Boundary check подтверждает наличие этих функций в `pos.html`.

### Edge Cases

- Недостаток общего ингредиента между несколькими строками.
- Ручная цена с запятой и округлением до копеек.
- Одинаковые и разные наборы модификаторов.
- Удаление последней позиции WEB-заказа.
- Свайп отменён или короче порога.
- Click без предварительного touchstart.

## Requirements *(mandatory)*

- **FR-001**: Сохранить прежние cart line fields и `currentOrderSession`.
- **FR-002**: Проверять `canFulfillCart` до увеличения или добавления.
- **FR-003**: Сохранить правила объединения modifier lines и отдельной manual-price line.
- **FR-004**: Удаление последней строки должно очищать существующий order context.
- **FR-005**: Инициализировать swipe state локально, чтобы click был безопасен без touchstart.
- **FR-006**: Не переносить parking, payment, finalization, stock mutation, receipt или printing.
- **FR-007**: Не менять storage keys, prefix, JSON formats, сеть или sync.
- **FR-008**: Production-компонент исполняется fixture до `loadAll()`.
- **FR-009**: Версия и `project.pbxproj` остаются неизменными.

## Success Criteria *(mandatory)*

- **SC-001**: Исходные строки функций перенесены без изменений, кроме явной инициализации swipe state.
- **SC-002**: Modifier, stock, quantity, removal, manual-price и click regressions проходят.
- **SC-003**: Полный Node suite и Simulator build проходят.
- **SC-004**: В `pos.html` нет дубликата API модуля и остаются critical operations.
