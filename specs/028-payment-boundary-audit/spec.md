# Feature Specification: аудит границы оплаты

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Audit complete; one P1 follow-up required

**Input**: Проверить оплату, чеки и связанные данные на потерю, дублирование и неверный порядок операций до следующего модульного переноса.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Одиночная оплата фиксируется атомарно (Priority: P1)

Кассир подтверждает оплату наличными или картой; чек, остатки, смена и очищенная текущая сессия сохраняются одной восстанавливаемой операцией до печати и сетевой публикации лояльности.

### User Story 2 - Раздельная оплата не теряет уже принятые части (Priority: P1)

После подтверждения одной части оплаты перезапуск приложения или уход с экрана не должен забывать, что деньги уже были приняты.

### User Story 3 - Повторное действие не создаёт второй чек (Priority: P1)

Пока critical commit выполняется, повторный вызов оплаты отклоняется; после успешной оплаты пустая корзина не создаёт дубликат.

### User Story 4 - Ошибка локального хранения сохраняет исходное состояние (Priority: P1)

Если journal не создан, чек, остатки и корзина не меняются. Если сбой произошёл после journal, запуск завершает все связанные записи.

## Requirements *(mandatory)*

- **FR-001**: Audit MUST trace totals, stock, receipt, shift, session, print and loyalty ordering.
- **FR-002**: Audit MUST distinguish durable guarantees from UI-only assumptions.
- **FR-003**: Confirmed runtime defects MUST be fixed in a separate feature stage.
- **FR-004**: Audit MUST NOT change runtime, storage, UI, network or version.
- **FR-005**: Existing payment and recovery tests MUST remain green.

## Success Criteria *(mandatory)*

- **SC-001**: Every payment side effect has a documented position before or after durable commit.
- **SC-002**: Data-loss and duplicate-payment paths have explicit conclusions.
- **SC-003**: Confirmed risks have priority, reproduction and a bounded follow-up.
- **SC-004**: Full automated suite passes with no production-code diff.

