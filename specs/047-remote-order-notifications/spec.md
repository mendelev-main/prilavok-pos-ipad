# Feature Specification: системные уведомления о WEB-заказах

**Roadmap**: R12
**Baseline**: `55839c8`

## Problem

Текущий звук создаётся WKWebView только при активном приложении. После блокировки iPad выполнение
страницы приостанавливается, поэтому сотрудник может не заметить новый онлайн-заказ.

## User Scenarios

### US1 — заблокированный iPad сообщает о заказе

После подтверждения телефона и атомарного создания WEB-заказа iPad получает системное уведомление
«Новый онлайн-заказ». При разрешённом звуке iPad воспроизводит системный сигнал даже на экране блокировки.

### US2 — активный POS не проигрывает двойной звук

В foreground системный push показывает баннер, а выбранный в POS звук воспроизводится один раз.
Существующий SSE продолжает доставлять сам заказ в раздел «События».

### US3 — сбой push не влияет на заказ и кассу

Недоступность APNs, отсутствие разрешения или устаревший token не отменяют заказ, оплату или локальную
работу POS. Durable outbox повторяет неудачную доставку с ограниченной задержкой.

## Functional Requirements

- **FR-001**: Push job MUST be created in the same database transaction as a new order.
- **FR-002**: Only authenticated active POS devices MAY register an APNs token.
- **FR-003**: APNs credentials MUST remain backend-only secrets.
- **FR-004**: Locked/background iPad MUST receive an alert and optional default system sound.
- **FR-005**: Foreground delivery MUST avoid a duplicate system/custom sound.
- **FR-006**: Push payload MUST NOT expose customer name, phone, address or comment on the lock screen.
- **FR-007**: Push failure MUST NOT roll back or block order creation or any POS operation.
- **FR-008**: Invalid/unregistered APNs tokens MUST be disabled without deleting POS data.
- **FR-009**: The existing notification sound toggle MUST also control locked-screen push sound.
- **FR-010**: Catalog synchronization, storage keys and WEB EventSource behavior MUST remain unchanged.

## Success Criteria

- **SC-001**: Automated tests prove transactional enqueue, token replacement and retry behavior.
- **SC-002**: Simulator build and all existing tests pass.
- **SC-003**: A physical locked iPad receives one alert with sound for a newly confirmed WEB-order.
- **SC-004**: With sound disabled, the locked iPad receives the alert without sound.

## Assumptions

- Один рабочий iPad остаётся основной целью, но схема безопасно поддерживает замену его APNs token.
- APNs provider key создаётся в Apple Developer и задаётся Railway secrets после code deployment.
