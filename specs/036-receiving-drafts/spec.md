# Feature Specification: устойчивые черновики приёмки

**Feature Branch**: `main`

**Created**: 2026-10-02

**Status**: Implemented

**Input**: Проверить начало и сохранение незавершённой приёмки, устранить публикацию черновика до storage commit и выделить узкую runtime-границу без изменения проведения прихода.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Начатая приёмка переживает перезапуск (Priority: P1)

При первом открытии заказа черновик и жёлтый статус появляются только после успешной записи в `purchaseOrders`.

### User Story 2 - «Завершить позже» не теряет ввод (Priority: P1)

При успешной записи форма закрывается; при storage failure заказ и экран не меняются, введённые данные остаются доступны для повтора.

### User Story 3 - Сохранённый черновик открывается локально (Priority: P1)

Уже сохранённый `receivingDraftV2` открывается без ненужной повторной записи и сохраняет нулевые и пустые значения.

### User Story 4 - Приёмка без заказа сохраняет прежний контракт (Priority: P1)

Standalone draft продолжает использовать `prilavok_receivingDraft`; сбой не закрывает форму, повторное нажатие не дублирует запись.

## Requirements *(mandatory)*

- **FR-001**: Новый order draft MUST записываться в отдельном снимке `purchaseOrders` до изменения state/UI.
- **FR-002**: Save order draft MUST публиковать новый массив только после adapter success.
- **FR-003**: Storage failure MUST оставить state, активный draft и страницу доступными для повтора.
- **FR-004**: Persisted order draft MUST открываться без redundant write.
- **FR-005**: Repeated open/save actions MUST NOT создавать повторные записи.
- **FR-006**: Существующие `receivingDraftV2`, legacy `receivingDraft`, `receivingIncomplete` и standalone key MUST остаться совместимыми.
- **FR-007**: Проведение прихода, товары, себестоимость, UI, сеть, версия и `project.pbxproj` MUST не изменяться.

## Success Criteria *(mandatory)*

- **SC-001**: Node regression и syntax checks проходят полностью.
- **SC-002**: Open/save success/failure/reopen/repeated-action tests проходят.
- **SC-003**: Simulator build успешен и bundled module совпадает с source.
- **SC-004**: `pos.html` больше не определяет `openReceivingDocument` и `saveReceivingDraft`.
