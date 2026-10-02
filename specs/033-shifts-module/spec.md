# Feature Specification: модуль кассовых смен

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Implemented

**Input**: Проверить финансовую логику смены, движения наличных и отчёты, исправить подтверждённые риски и выделить домен из `pos.html` без изменения совместимых данных и UI.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Полный цикл смены согласован (Priority: P1)

Кассир проводит cash/card/split продажи, возврат, внесение и изъятие, затем закрывает смену; экран, ожидаемая касса и итоговый payload показывают одинаковые значения.

### User Story 2 - Смена сохраняется до внешних действий (Priority: P1)

Открытие, движение и закрытие используют существующий critical journal; Telegram и печать запускаются только после локального commit.

### User Story 3 - Повреждённая касса не получает новые операции (Priority: P1)

Неконечный или отрицательный производный остаток блокирует открытие следующей смены, движения, доставку, наличный возврат и закрытие до записи.

### User Story 4 - Экран и отчёты сохраняют прежний контракт (Priority: P1)

История смен, модальные окна, Telegram/native payload и LAN-печать работают через те же глобальные функции и поля.

## Requirements *(mandatory)*

- **FR-001**: Consolidate current-shift access, totals, drawer balance, shift UI, local operations and shift report payload in one classic module.
- **FR-002**: The module MUST load before payment, receipts and startup because those consumers use shift globals.
- **FR-003**: Existing `prilavok_shifts`, order, cash movement and report payload formats MUST remain unchanged.
- **FR-004**: Open/movement/close MUST retain existing critical journal and post-commit side-effect ordering.
- **FR-005**: Cash/card/split, returns, deposits and withdrawals MUST produce one consistent expected drawer balance.
- **FR-006**: Non-finite or negative derived drawer values MUST block all new financial mutations.
- **FR-007**: The current administrator-password policy remains unchanged in this stage.
- **FR-008**: No version, `project.pbxproj`, sync trigger, storage migration or UI redesign is included.

## Success Criteria *(mandatory)*

- **SC-001**: Full Node regression and JavaScript syntax checks pass.
- **SC-002**: One mixed-shift test proves exact totals through close and report generation.
- **SC-003**: Corrupt drawer tests prove no state or storage mutation across protected operations.
- **SC-004**: Simulator build succeeds and bundled module matches source.
- **SC-005**: `pos.html` no longer defines `submitCloseShift` and decreases by the extracted domain.
