# Feature Specification: модуль клиентов и лояльности

**Roadmap**: R1, R8  
**Baseline**: `da62659`  
**Scope**: клиент заказа, loyalty lifecycle и административный интерфейс

## Problem

Клиентский и административный loyalty runtime остаётся двумя связанными блоками в `pos.html`.
Backend ID и названия программ вставляются в inline actions как quoted strings через HTML escaping;
после декодирования атрибута браузером кавычка может разорвать JavaScript-действие. Две функции
старого редактора не имеют рабочих call sites.

## User Scenarios

### US1 — безопасные административные действия

Совместимые строковые ID и названия не могут изменить исполняемый inline action. Открытие клиента,
изменение, включение и удаление программы получают исходные значения.

### US2 — неизменный loyalty flow

Поиск и выбор клиента, начисление после оплаченного чека, подарок, повтор после сети и reversal после
возврата работают по прежним API и не блокируют локальную оплату.

### US3 — единый доменный модуль

Активные customer/loyalty functions находятся в `Web/js/features/loyalty.js`. Доказанно
неиспользуемые legacy functions удалены.

## Functional Requirements

- **FR-001**: Inline action arguments from backend MUST use JSON serialization plus attribute escaping.
- **FR-002**: Existing customer search, selection and detach behavior MUST remain.
- **FR-003**: Paid-sale publish, pending retry and reversal ordering MUST remain.
- **FR-004**: Reward allocation MUST preserve paid-only and non-overlapping item rules.
- **FR-005**: Existing endpoints, timeout, payloads and global function names MUST remain.
- **FR-006**: Local payment MUST remain available when loyalty network calls fail.
- **FR-007**: Storage keys, local JSON, sync triggers and UI layout MUST not change.

## Success Criteria

- **SC-001**: Test executes generated actions with hostile-compatible values without running injected code.
- **SC-002**: Module load/API test proves loyalty loads before dependent feature modules and startup.
- **SC-003**: Existing phone, editor, payment, WEB customer, retry and reversal tests pass.
- **SC-004**: Legacy functions without call sites are absent.
- **SC-005**: Full Node suite, syntax checks, diagnostics and Simulator build pass.

