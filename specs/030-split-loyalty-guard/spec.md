# Feature Specification: проверка лояльности перед split-оплатой

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: In progress

**Input**: Применить существующую проверку подарка к раздельной оплате до принятия первой части.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Доступный подарок подтверждается (Priority: P1)

До создания частей раздельной оплаты M POS перепроверяет выбранный подарок и строит части по подтверждённой сумме чека.

### User Story 2 - Недоступный подарок блокирует оплату (Priority: P1)

Если подарок уже использован или недоступен, split screen не открывается и деньги не принимаются.

### User Story 3 - Offline-продолжение пересчитывает сумму (Priority: P1)

Если loyalty backend недоступен, кассир может продолжить без подарка; M POS удаляет redemption и только затем строит split по полной сумме.

### User Story 4 - Уже принятые части неизменны (Priority: P1)

Восстановленный durable split draft не проходит повторный пересчёт и сохраняет сумму, по которой уже были приняты деньги.

## Requirements *(mandatory)*

- **FR-001**: Split creation MUST use the existing loyalty guard before creating parts.
- **FR-002**: Unavailable reward MUST leave split state empty.
- **FR-003**: Offline continuation MUST clear reward selection before calculating parts.
- **FR-004**: Concurrent guard requests MUST collapse to one in-flight validation.
- **FR-005**: Cancel MUST clear the deferred action.
- **FR-006**: Existing durable drafts, receipt formats, storage keys and network boundaries remain unchanged.

## Success Criteria *(mandatory)*

- **SC-001**: Tests prove valid, unavailable and offline paths.
- **SC-002**: Split cents equal the post-guard receipt total.
- **SC-003**: Full Node suite and Simulator build pass.

