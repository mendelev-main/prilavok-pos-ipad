# Feature Specification: модуль интерфейса приёмки

**Roadmap**: R1, R8  
**Baseline**: `5f4a79a`  
**Scope**: экран, редактор и история приёмки

## Problem

После выделения draft и completion boundaries отображение приёмки остаётся большим связным блоком
в `pos.html`. В истории количество из вложенной строки совместимого backup вставляется в HTML без
экранирования. Две функции старой формы приёмки не имеют call sites.

## User Scenarios

### US1 — безопасная история

Старое или подготовленное значение количества не может добавить HTML в карточку исторической
приёмки. Корректные числовые количества отображаются как раньше.

### US2 — неизменный рабочий поток

Экран «Приёмка», история, новая приёмка, отдельная страница заказа, редактирование строк и возврат
назад сохраняют прежний UI и взаимодействие с draft/completion modules.

### US3 — единый доменный модуль

Активные presentation/editor functions находятся в `Web/js/features/receiving-ui.js`, а
доказанно неиспользуемые `addReceivingLine` и `removeReceivingLine` удалены.

## Functional Requirements

- **FR-001**: Quantity in receiving history MUST be escaped as text.
- **FR-002**: Supplier, invoice, product and status presentation MUST preserve current escaping.
- **FR-003**: Existing global function names used by HTML, drafts and completion MUST remain.
- **FR-004**: Order receiving page and standalone inline panel MUST preserve current behavior.
- **FR-005**: Storage keys, JSON shape, calculations, UI layout, network and sync MUST not change.
- **FR-006**: Functions with no repository call sites MAY be removed with a regression assertion.

## Success Criteria

- **SC-001**: Test proves imported quantity cannot inject HTML.
- **SC-002**: Module load/API test proves load order before drafts/completion/startup.
- **SC-003**: Existing receiving UI, draft, completion, unit and history tests pass.
- **SC-004**: Dead receiving-line helpers are absent from runtime.
- **SC-005**: Full Node suite, syntax checks and Simulator build pass.

