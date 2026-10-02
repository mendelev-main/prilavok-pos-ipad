# Feature Specification: событийная публикация остатков

**Roadmap**: R1, R3, R4, R8
**Baseline**: `b4b1810`
**Scope**: отправлять последний сохранённый снимок availability после stock commit без heartbeat

## Problem

POS сейчас публикует availability каждые десять минут и при возврате приложения на экран. Это
регулярно обращается к backend без изменения остатков и одновременно может оставить сайт устаревшим
почти на десять минут после продажи последнего товара. Нужна событийная публикация после успешно
сохранённого изменения склада без задержки локальной операции.

## User Scenarios

### US1 — последняя продажа быстро закрывает товар для WEB

После устойчивого проведения оплаты POS завершает локальный чек и в фоне отправляет полный снимок
доступности. Составной товар получает количество из актуальных сохранённых ингредиентов.

### US2 — быстрые операции не теряют последний остаток

Если второй stock commit происходит во время активного запроса, POS помечает снимок устаревшим и
после завершения первого запроса отправляет новый снимок. Старые revision не заменяют новые.

### US3 — offline POS остаётся полностью рабочим

Ошибка storage не запускает публикацию. Ошибка или timeout backend не отменяет оплату, возврат,
приёмку, инвентаризацию или изменение товара. Автоматического retry по таймеру, запуску, foreground,
online event или восстановлению сети нет; следующая stock-changing операция создаёт новую попытку.

### US4 — все подтверждённые изменения склада актуализируют WEB

Фоновая публикация запускается после успешной оплаты, возврата, приёмки, фиксации инвентаризации и
сохранения карточки товара. Ручная публикация меню остаётся отдельной операцией.

### US5 — сайт не принимает больше доступного остатка

Сайт получает доступное количество вместе с меню, блокирует отсутствующие товары и ограничивает
увеличение количества в корзине. Перед оформлением остатки перечитываются. Окончательная проверка и
резерв выполняются атомарно после подтверждения телефона, поэтому два одновременных заказа не могут
использовать одну и ту же последнюю единицу.

## Functional Requirements

- **FR-001**: Availability MUST publish only after the corresponding product snapshot is durably stored.
- **FR-002**: Payment and other local operations MUST NOT await availability network completion.
- **FR-003**: A trigger received during an active request MUST result in a later snapshot of newest storage.
- **FR-004**: Storage failure MUST prevent availability network requests.
- **FR-005**: Network failure MUST leave local POS state and completed operations unchanged.
- **FR-006**: No availability request may start from a timer, app launch, foreground, visibility or online event.
- **FR-007**: Snapshot format, endpoint, device key, revision and ingredient availability rules MUST remain compatible.
- **FR-008**: Manual menu synchronization MUST remain manual-only and may publish availability after success.
- **FR-009**: Product JSON, storage keys and authoritative POS data MUST remain unchanged.
- **FR-010**: Backend MUST subtract open confirmed WEB reservations from the newest POS snapshot.
- **FR-011**: Final order creation and reservation MUST be one atomic database operation.
- **FR-012**: A paid WEB receipt MUST let POS settle its backend reservation without double subtraction.
- **FR-013**: Pending settlement identity MUST survive an app restart through existing paid receipt history.

## Success Criteria

- **SC-001**: Tests prove payment triggers only after durable commit and never waits for network.
- **SC-002**: Tests prove rapid triggers coalesce without losing the newest snapshot.
- **SC-003**: Tests prove startup, foreground and online events create no availability request.
- **SC-004**: Payment, return, receiving, inventory and product save trigger publication only after success.
- **SC-005**: Full Node suite, syntax, diagnostics and Simulator build pass.
- **SC-006**: A concurrent oversized order is rejected without creating a partial order or reservation.
- **SC-007**: Website quantity controls and checkout use current effective availability.

## Assumptions

- При отсутствии интернета сайт может временно показывать устаревшие остатки; это принятый риск.
- Новая попытка после сетевой ошибки появится только при следующем подтверждённом изменении склада
  или ручной синхронизации меню.
- В production используется один активный iPad; при отсутствии ровно одного активного устройства
  backend безопасно запрещает оформление, пока источник availability не определён.
