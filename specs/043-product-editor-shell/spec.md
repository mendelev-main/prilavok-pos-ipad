# Feature Specification: оболочка редактора товара

**Roadmap**: R1, R8
**Baseline**: `5623b39`
**Scope**: открытие, отображение, навигация и dirty-state карточки товара

## Problem

UI-runtime карточки товара остаётся связанным блоком в `pos.html`, хотя единицы, рецептуры и
модификаторы уже выделены. Строковые product ID в строках таблицы товаров передаются в действия
открытия и WEB-переключателя через quoted interpolation, небезопасную после декодирования атрибута.

## User Scenarios

### US1 — карточка открывается и закрывается без потери черновика

Редактирование загружает прежние поля и возвращает пользователя к списку. При изменении карточки
выход требует сохранить, отбросить или остаться; повторное сохранение во время pending блокируется.

### US2 — неизменная навигация карточки

Разделы «Основное», «Состав и остатки», «Модификаторы», «Где используется» и «Онлайн-меню» сохраняют
текущую разметку и вызовы доменных функций.

### US3 — безопасные действия списка товаров

Открытие строки с клавиатуры/касания и WEB-переключатель передают исходный product ID как данные,
включая совместимые специальные символы из backup.

## Functional Requirements

- **FR-001**: Product editor markup, fields, navigation and focus restoration MUST remain unchanged.
- **FR-002**: Dirty snapshot and save/discard/stay behavior MUST remain unchanged.
- **FR-003**: Usage links and receipt/parked counters MUST remain unchanged.
- **FR-004**: Product IDs in catalog actions MUST use JSON serialization plus attribute escaping.
- **FR-005**: `saveProduct`, photo processing, storage, product JSON, network and sync MUST not change.
- **FR-006**: Existing global function names MUST remain available to HTML and feature modules.

## Success Criteria

- **SC-001**: Existing editor dirty/usage tests pass against the module boundary.
- **SC-002**: Module load/API test proves correct ordering before catalog and startup.
- **SC-003**: Generated catalog actions preserve hostile-compatible ID without executing it.
- **SC-004**: Full Node suite, syntax, diagnostics and Simulator build pass.
