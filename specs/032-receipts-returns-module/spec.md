# Feature Specification: чеки и возвраты

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Implemented

**Input**: Проверить критическую логику чеков и возвратов, исправить подтверждённые ошибки и вынести границу из `pos.html` без изменения совместимых данных и интерфейса.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - История чеков работает без изменений (Priority: P1)

Кассир выбирает, просматривает и повторно печатает локальный чек через прежний интерфейс.

### User Story 2 - Полный возврат атомарен (Priority: P1)

Возврат либо вместе сохраняет остатки, отметку чека и кассовое движение через critical journal, либо не меняет состояние.

### User Story 3 - Ожидаемая касса учитывает возврат один раз (Priority: P1)

После наличной продажи и полного возврата ожидаемая сумма в кассе возвращается к исходной, а возврат остаётся видимым отдельным движением.

### User Story 4 - Повреждённый чек не изменяет данные (Priority: P1)

Неконечная сумма чека, неконечная/отрицательная наличная часть или наличная часть больше итога блокируют возврат до изменения остатков, чека и смены.

## Requirements *(mandatory)*

- **FR-001**: Move the contiguous receipt history, reprint and return block into one classic script loaded after payment and before startup.
- **FR-002**: Existing global handler names and receipt UI markup MUST remain available.
- **FR-003**: Return MUST preserve the existing `products`/`orders`/`shifts` critical journal transaction and loyalty sequencing.
- **FR-004**: Existing receipt, payment, stock snapshot and cash movement formats MUST remain unchanged.
- **FR-005**: Expected drawer cash MUST not subtract one cash refund both as removed revenue and as a withdrawal.
- **FR-006**: Invalid non-finite or inconsistent return amounts MUST fail before any state or storage mutation.
- **FR-007**: No version, `project.pbxproj`, network trigger, automatic sync or UI redesign is included.

## Success Criteria *(mandatory)*

- **SC-001**: Full Node regression and JavaScript syntax checks pass.
- **SC-002**: Return failpoint recovery, duplicate prevention, historical stock snapshot and legacy receipt tests pass against the production module.
- **SC-003**: Cash sale 10 followed by cash return 10 leaves a drawer opened with 100 at 100.
- **SC-004**: Simulator build succeeds and bundled module matches its source.
- **SC-005**: `pos.html` no longer defines `processFullReturn` and decreases by the extracted block.
