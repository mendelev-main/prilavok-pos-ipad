# Feature Specification: безопасное завершение приёмки

**Roadmap**: R1, R8  
**Baseline**: `3fc0265`  
**Scope**: локальное проведение уже подготовленного документа приёмки

## Problem

Завершение приёмки атомарно пишет товары, заказ и историю через существующий critical journal,
но не занимает общий `criticalOperationBusy`. Пока запись ожидает storage, другая критическая
операция может начать собственное сохранение. Логика проведения также остаётся внутри `pos.html`.

## User Scenarios

### US1 — одна критическая операция за раз

Если другая критическая операция уже сохраняется, приёмка не начинает новый journal и не меняет
остатки, себестоимость, заказ или историю.

### US2 — приёмка блокирует конкурирующие действия

С момента начала проведения и до его завершения общий busy guard занят. Повторное подтверждение
не создаёт второй приход.

### US3 — storage-first публикация

Остатки, себестоимость, статус заказа и история появляются в runtime только после успешного
critical commit. При ошибке до journal исходное состояние остаётся доступно для повтора. При
частичной записи сохранённый journal восстанавливает единый снимок после запуска.

### US4 — совместимость

Существующие ключи, поля заказов/приёмок/товаров, формулы единиц и средневзвешенной стоимости,
экран и тексты сохраняются. Неизвестные legacy-поля не удаляются.

## Functional Requirements

- **FR-001**: `applyReceivingDocument` MUST проверять и занимать общий `criticalOperationBusy`.
- **FR-002**: Guard MUST освобождаться при success и failure.
- **FR-003**: Runtime state MUST публиковаться только после `commitCriticalStorage`.
- **FR-004**: Повторное подтверждение MUST не создавать второй документ.
- **FR-005**: Запись MUST оставаться одним journal для `products`, `purchaseOrders`, `receivings`
  и `receivingDraft` для standalone-приёмки.
- **FR-006**: При interrupted write восстановление MUST приводить все ключи к одному снимку.
- **FR-007**: Completion boundary MUST быть вынесен в classic module без изменения публичных имён.
- **FR-008**: Storage keys, JSON shape, UI, network, sync, version и `project.pbxproj` MUST не меняться.

## Success Criteria

- **SC-001**: Автотест доказывает отказ при занятом global guard без storage write.
- **SC-002**: Автотест доказывает занятый guard во время ожидающего commit и один приход.
- **SC-003**: Success/failure/restart tests подтверждают storage-first и recovery.
- **SC-004**: `pos.html` больше не определяет completion functions; module загружен до startup.
- **SC-005**: Полный Node suite, syntax checks и Simulator build проходят.

