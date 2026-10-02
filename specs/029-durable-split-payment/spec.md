# Feature Specification: надёжная раздельная оплата

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: In progress

**Input**: Устранить P1 риск из payment audit: уже принятая часть split-оплаты не должна теряться до создания чека.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Каждая принятая часть сохраняется (Priority: P1)

После подтверждения наличной или карточной части M POS сначала надёжно сохраняет её в текущей сессии и только затем показывает «Оплачено».

### User Story 2 - Незавершённая оплата восстанавливается (Priority: P1)

После перезапуска приложение открывает сохранённую split-оплату с теми же оплаченными частями и остатком.

### User Story 3 - Оплаченную часть нельзя тихо отбросить (Priority: P1)

Кнопки возврата не закрывают payment flow, пока существует принятая часть; кассир завершает чек из восстановленного экрана.

### User Story 4 - Старые сессии остаются совместимыми (Priority: P1)

Сессии без payment draft загружаются без изменений. Неверный или не совпадающий с текущей суммой draft не применяется как оплата.

## Requirements *(mandatory)*

- **FR-001**: A paid split part MUST be committed through critical storage before live paid state.
- **FR-002**: Draft MUST use optional versioned data inside existing `currentOrderSession`.
- **FR-003**: Restore MUST validate methods, non-negative finite cents, total and cash details.
- **FR-004**: A draft with paid parts MUST survive restart and reopen the split screen.
- **FR-005**: Back actions MUST NOT silently discard paid parts.
- **FR-006**: Final payment MUST clear the draft in the existing atomic payment commit.
- **FR-007**: Finalization MUST reject malformed methods and negative/non-finite amounts.
- **FR-008**: Existing keys, receipt/product/shift formats, network and UI style remain unchanged.

## Success Criteria *(mandatory)*

- **SC-001**: Injected draft-journal failure leaves the part unpaid.
- **SC-002**: Restart restores paid parts from the unchanged session key.
- **SC-003**: Completed sale still produces one receipt and clears the session atomically.
- **SC-004**: Full Node suite and Simulator build pass; built bundle matches source.

