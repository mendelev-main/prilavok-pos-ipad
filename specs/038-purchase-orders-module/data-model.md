# Data Model: модуль заказов поставщикам

Новых сущностей и полей нет.

- `products`: сохраняет прежние purchase defaults (`purchaseUnit`, `purchasePackSize`,
  `purchaseContentUnit`) вместе со всеми неизвестными полями.
- `purchaseOrders`: прежний `requestVersion: 1`, supplier snapshot, items, status and timestamp.
- `receivings`: при административном удалении получает прежнюю audit row.

Удаление legacy helpers не удаляет сохранённые данные и не требует миграции.

