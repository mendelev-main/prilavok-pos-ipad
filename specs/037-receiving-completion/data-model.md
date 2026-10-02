# Data Model: безопасное завершение приёмки

Новых сущностей и полей нет.

## Existing atomic snapshot

- `products`: для принятых простых товаров меняются `stock` и `cost`.
- `purchaseOrders`: при связанной приёмке меняются `status`, `receivedAt`, `receivedItems`,
  `shortage`, очищаются существующие draft-поля.
- `receivings`: добавляется прежняя immutable history row.
- `receivingDraft`: standalone draft очищается значением `null`.

Все остальные и неизвестные поля копируются через `storageSnapshot` без удаления.

