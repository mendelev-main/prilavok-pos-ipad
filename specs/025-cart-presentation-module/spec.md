# Feature Specification: модуль представления текущего заказа

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Automated acceptance complete; device verification deferred

**Input**: Продолжить постепенную production-ready миграцию после POS navigation, не затрагивая критическую оплату.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Текущий заказ отображается без изменений (Priority: P1)

Кассир видит позиции, скидки, модификаторы, комментарии, доставку, loyalty discount и итог так же, как до рефакторинга.

**Independent Test**: Сформировать корзину со скидкой и проверить расчёт и HTML production-компонента.

### User Story 2 - Редактирование позиции и параметров сохраняется локально (Priority: P2)

Кассир меняет количество, комментарий, скидку, тип заказа и тариф доставки через прежние модальные окна.

**Independent Test**: Существующие delivery/storage regressions и прямой API contract проходят с вынесенным компонентом.

### User Story 3 - Оплата остаётся за границей (Priority: P1)

Разработчик сопровождает представление заказа отдельно, а создание чека, списание, печать, парковка и payment flow не перемещаются.

**Independent Test**: Diff показывает только contiguous presentation block; payment functions остаются inline.

### Edge Cases

- Пустая корзина и закрытая смена.
- Процентная и фиксированная скидка больше стоимости строки.
- Бесплатный тариф доставки.
- Товар с модификаторами и HTML в комментарии.
- Увеличение количества при недостаточном остатке.

## Requirements *(mandatory)*

- **FR-001**: Сохранить расчёт скидки, подытога и отображаемого итога.
- **FR-002**: Сохранить прежний UI, inline handlers и global API.
- **FR-003**: Сохранить запись текущей сессии через существующий `saveCurrentOrderSession`.
- **FR-004**: Не менять storage keys, prefix и JSON-форматы.
- **FR-005**: Не переносить add-to-cart, modifiers, stock validation, parking, payment, receipt or printing.
- **FR-006**: Не добавлять сеть, синхронизацию или таймеры.
- **FR-007**: Production-компонент должен исполняться тестовой fixture до `loadAll()`.
- **FR-008**: Версия и `project.pbxproj` остаются неизменными.

## Success Criteria *(mandatory)*

- **SC-001**: Строки реализации совпадают с baseline; исключён только межблочный пустой разделитель.
- **SC-002**: Pricing/render/API regressions проходят.
- **SC-003**: Полный Node suite и Simulator build проходят.
- **SC-004**: В `pos.html` нет дубликата функций компонента.
