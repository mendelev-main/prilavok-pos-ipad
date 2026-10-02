# Implementation Plan: событийная публикация остатков

## Context

**Runtime**: classic JavaScript in WKWebView
**Storage source**: persisted `products`, `network`, `webAvailabilityRevision`
**Network**: existing `POST /api/availability/snapshot`
**Triggers**: completed stock-changing commits and explicit menu synchronization

## Constitution Check

- POS remains source of truth and local commit completes before network.
- Network never blocks or rolls back local operations.
- Ten-minute, launch, foreground and connectivity triggers are removed by explicit user decision.
- Product/storage formats and manual catalog synchronization remain unchanged.
- The accepted offline risk is documented rather than hidden by automatic retry.

## Design

Create `Web/js/features/availability.js`. A public `publishAvailability()` marks a pending generation
and starts one background drain. The drain reads products from storage for every generation. A trigger
during fetch sets pending again, so a second newest snapshot follows. Failure stops the drain without
timer/reconnect retry. `onAvailabilityAppState(false)` only aborts an in-flight request.

Call `void publishAvailability()` immediately after successful local publication in payment, return,
receiving, inventory and product persistence modules. Remove `startAvailabilitySchedule()` and its
startup/foreground behavior. Keep the existing explicit call after successful manual menu sync.

Backend сохраняет физический snapshot отдельно от открытых WEB-резервов. Публичное количество равно
`physical - open reservations`. Создание подтверждённого заказа блокирует строку состояния устройства,
повторно проверяет эффективный остаток и в одной транзакции создаёт заказ с резервом. Оплата WEB-заказа
на POS передаёт его backend ID; после успешного snapshot резерв считается погашенным. При перезапуске
неотправленные ID восстанавливаются из существующей локальной истории оплаченных чеков.

Сайт получает availability при первоначальной загрузке, открытии корзины и непосредственно перед
checkout. Локальные controls дают быструю обратную связь, а атомарная backend-проверка остаётся
окончательной защитой от устаревшей вкладки и параллельных заказов.

## Validation

Add module boundary, no-heartbeat, commit-order, failure isolation, restart recovery and coalescing
regressions. Execute the SQL migration in PGlite, including concurrent reservation and settlement cases.
Run full Node, production syntax, diagnostics, unsigned Simulator build and bundle hash.
