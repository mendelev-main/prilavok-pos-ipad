# Feature Specification: модуль отложенных заказов

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Automated acceptance complete; device verification deferred

**Input**: Выделить парковку заказов и устранить риск потери отложенного заказа при ошибке удаления.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Заказ откладывается атомарно (Priority: P1)

Кассир откладывает подписанный текущий заказ; parked row и очищенная current session фиксируются одной восстанавливаемой операцией до изменения интерфейса и кухонной печати.

### User Story 2 - Заказ восстанавливается атомарно (Priority: P1)

Кассир открывает отложенный заказ; current session и удаление parked copy восстанавливаются вместе, включая доставку, WEB context, клиента и kitchen print state.

### User Story 3 - Ошибка удаления не теряет заказ (Priority: P1)

Если local storage не принимает удаление, отложенный заказ остаётся в памяти и persisted storage, а оператор видит ошибку.

### User Story 4 - Оплата остаётся отдельной границей (Priority: P1)

Payment, receipt, stock mutation, returns and printing finalization не перемещаются в этом этапе.

### Edge Cases

- Двойное нажатие «Отложить» или «Удалить».
- Сбой до journal и после записи journal.
- Восстановление при непустой текущей корзине.
- WEB-заказ с подтверждённым клиентом.
- Уже напечатанные и новые kitchen lines.
- Удаление отсутствующего parked id.

## Requirements *(mandatory)*

- **FR-001**: Park and resume MUST retain existing critical journal semantics.
- **FR-002**: Delete MUST persist through `commitCriticalStorage` before replacing state.
- **FR-003**: Delete failure MUST retain both state and stored parked rows.
- **FR-004**: Concurrent parked mutation MUST be rejected by existing busy guard.
- **FR-005**: Existing parked/order/session JSON shapes and keys MUST remain unchanged.
- **FR-006**: Kitchen print MUST occur only after durable park.
- **FR-007**: Payment, receipts, stock, returns and loyalty publication remain outside.
- **FR-008**: No network, sync, timer, version or project-file change.
- **FR-009**: Production component MUST run in the test fixture before startup.

## Success Criteria *(mandatory)*

- **SC-001**: Park/resume interruption and recovery tests remain green.
- **SC-002**: Delete success and failure tests prove storage-first behavior.
- **SC-003**: Full Node suite and Simulator build pass.
- **SC-004**: Module is included unchanged in the built app.
