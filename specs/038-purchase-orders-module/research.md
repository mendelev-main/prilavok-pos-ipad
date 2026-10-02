# Research: модуль заказов поставщикам

На baseline `ff43ba7` создание заказа корректно строит снимки `products` и `purchaseOrders` и пишет
их одним recoverable journal. Однако `render()` и `viewPurchaseOrder()` выполняются внутри того же
outer `try/catch`. Исключение после commit возвращает `false` и показывает «Заказ не сформирован»,
хотя storage и state уже содержат заказ. Это создаёт риск повторного заказа.

Просмотр заказа формирует inline actions с ID внутри ручных одинарных кавычек. Обычные ID из `uid()`
безопасны, но backup допускает любой непустой строковый ID. Используем уже принятый в коде шаблон
`escapeAttr(JSON.stringify(id))`.

Repository-wide search не нашёл call sites для `productConsumptionSince`,
`consumedSimpleProductQty`, `updatePurchaseQty` и `openSupplyHistory`. Текущий UI использует
`updatePurchaseRequest`, inline history panels и отдельные view functions.

