# Feature Specification: модуль оплаты

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: In progress

**Input**: Вынести проверенный payment runtime из `pos.html` без изменения поведения и данных.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Оплата работает без изменений (Priority: P1)

Кассир использует cash, card или split с теми же экранами, расчётами, delivery checks и loyalty guard.

### User Story 2 - Продажа сохраняется атомарно (Priority: P1)

Products, receipt, shift and cleared current session retain the existing critical journal order.

### User Story 3 - Durable split восстанавливается (Priority: P1)

Versioned payment draft, Back guards and restart recovery remain available through the same globals.

### User Story 4 - Receipt and external effects retain order (Priority: P1)

Paid receipt UI, loyalty publication and printing still run only after successful local commit.

## Requirements *(mandatory)*

- **FR-001**: Move one contiguous payment/paid-receipt block without functional edits.
- **FR-002**: Existing global handler names MUST remain available.
- **FR-003**: Module MUST load before `loadAll()` because startup can restore a payment draft.
- **FR-004**: Tests MUST execute the production module, not a copied implementation.
- **FR-005**: Receipt history, returns and printer orchestration MUST remain outside this stage.
- **FR-006**: Storage keys/shapes, UI, network, version and project file MUST remain unchanged.

## Success Criteria *(mandatory)*

- **SC-001**: Full payment, recovery, loyalty, stock and print tests pass.
- **SC-002**: Inline runtime no longer defines `finalizePayment`.
- **SC-003**: Simulator build succeeds and bundled module matches source.
- **SC-004**: `pos.html` decreases by the moved block with no behavior rewrite.

