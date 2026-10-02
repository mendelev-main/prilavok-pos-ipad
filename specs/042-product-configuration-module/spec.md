# Feature Specification: модуль конфигурации товара

**Roadmap**: R1, R8  
**Baseline**: `b11d284`  
**Scope**: единицы, рецептуры, модификаторы и связанные элементы редактора товара

## Problem

Единицы измерения, редактор рецептуры и редактор модификаторов занимают крупный связанный блок в
`pos.html`. Два списка товаров передают совместимые строковые product ID в inline actions через
quoted HTML escaping; после декодирования атрибута кавычка может изменить JavaScript-действие.

## User Scenarios

### US1 — совместимые единицы и рецептуры

Старые товары без единиц и новые товары с `piece/kg/g/l/ml` открываются, пересчитываются и
сохраняются по прежним правилам. Вложенные рецептуры продолжают списывать исходные базовые количества.

### US2 — безопасные модификаторы

Выбор ингредиента, выбор товара-модификатора и выбор модификатора при продаже передают исходный ID
как данные, включая кавычки и специальные символы из совместимого backup.

### US3 — отдельная граница конфигурации

Связанные функции находятся в `Web/js/features/product-configuration.js`, сохраняя прежний global API.
Сохранение товара, фото и основной shell редактора остаются в `pos.html`.

## Functional Requirements

- **FR-001**: Storage keys, product JSON and recipe/modifier shapes MUST remain unchanged.
- **FR-002**: Unit conversion, base-unit persistence and legacy no-unit behavior MUST remain unchanged.
- **FR-003**: Recipe cycle checks, component quantities and composite yield MUST remain unchanged.
- **FR-004**: Modifier validation, stock consumption and cart price deltas MUST remain unchanged.
- **FR-005**: Product IDs in inline actions MUST use JSON serialization plus attribute escaping.
- **FR-006**: Product save, photo upload, UI layout, network and sync triggers MUST not change.
- **FR-007**: Existing global function names used by HTML and feature modules MUST remain available.

## Success Criteria

- **SC-001**: Generated editor/cart actions preserve hostile-compatible IDs without executing them.
- **SC-002**: Existing unit, recipe, modifier, sale and return tests pass unchanged.
- **SC-003**: Module load/API test proves load before dependent modules and startup.
- **SC-004**: Full Node suite, syntax checks, audit diagnostics and Simulator build pass.
