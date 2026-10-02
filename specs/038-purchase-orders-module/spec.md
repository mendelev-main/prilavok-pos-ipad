# Feature Specification: модуль заказов поставщикам

**Roadmap**: R1, R8  
**Baseline**: `ff43ba7`  
**Scope**: создание, удаление, просмотр, история и передача заказов поставщикам

## Problem

Заказы уже сохраняются через critical journal, но durable commit и presentation находятся в одном
`try/catch`: ошибка `render()` или открытия карточки после успешной записи сообщает, что заказ не
сформирован. Повтор оператора может создать дубликат. Домен также разделён между двумя удалёнными
участками `pos.html` и содержит доказанно неиспользуемые legacy helpers.

## User Scenarios

### US1 — достоверный результат создания

После успешного journal commit заказ считается созданным независимо от последующей ошибки UI.
Оператор не получает ложное сообщение о failure и не провоцируется повторить сохранённый заказ.

### US2 — storage-first и защита повторного действия

Пока commit ожидает завершения, исходные товары, список заказов и draft остаются неизменными, общий
critical guard занят, а повторное подтверждение не начинает вторую запись.

### US3 — безопасные восстановленные идентификаторы

ID заказа из совместимого backup не может разорвать HTML/inline action в карточке просмотра или
диалоге удаления.

### US4 — постепенная модульная архитектура

Активные функции заказов поставщикам находятся в одном classic module. Доказанно неиспользуемые
`productConsumptionSince`, `consumedSimpleProductQty`, `updatePurchaseQty` и `openSupplyHistory`
удалены; поведение текущего UI не меняется.

## Functional Requirements

- **FR-001**: Создание MUST отделять validation/commit failure от post-commit presentation failure.
- **FR-002**: State MUST публиковаться только после успешного `commitCriticalStorage`.
- **FR-003**: `criticalOperationBusy` MUST удерживаться до окончания commit и освобождаться всегда.
- **FR-004**: Повторное создание во время pending commit MUST не писать второй journal.
- **FR-005**: Unknown product/order fields MUST сохраняться в полных снимках.
- **FR-006**: Dynamic order IDs in inline handlers MUST проходить JSON + attribute escaping.
- **FR-007**: Existing keys, order/item JSON fields, unit conversion, UI, network and sync MUST not change.
- **FR-008**: Active purchase-order runtime MUST быть вынесен в `Web/js/features/purchase-orders.js`.

## Success Criteria

- **SC-001**: Тест доказывает storage-first и один commit при повторном действии.
- **SC-002**: Тест доказывает success result после commit при исключении presentation.
- **SC-003**: Тест с кавычками/HTML в legacy ID не создаёт исполняемый inline fragment.
- **SC-004**: Existing create/delete/recovery/unit/share tests проходят без изменения fixtures.
- **SC-005**: Full Node suite, syntax checks and Simulator build pass.

