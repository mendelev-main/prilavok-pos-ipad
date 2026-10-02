# Data Model: модуль интерфейса приёмки

Новых сущностей, полей и миграций нет. Модуль только читает существующие:

- `purchaseOrders` для списка ожидающих поставок;
- `receivings` для истории;
- transient `window._receivingDraft` для редактора документа;
- `suppliers` и `products` для подписей и единиц.

Escaping меняет только HTML presentation, а не сохранённое значение.

