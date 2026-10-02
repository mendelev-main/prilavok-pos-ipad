# Research: безопасное завершение приёмки

На baseline `3fc0265` расчёт строк и средневзвешенной себестоимости выполняется на снимках, а
`products`, `purchaseOrders` и `receivings` записываются одним `commitCriticalStorage`. Публикация
state происходит после commit; interrupted write восстанавливается при следующем `loadAll`.

Найденный разрыв: в отличие от оплаты, возврата, смен, инвентаризации и заказов поставщикам,
`applyReceivingDocument` не проверяет и не занимает `criticalOperationBusy`. Два разных critical
flow могут пройти проверку `criticalStorageRecoveryPending` до того, как первый journal станет
виден второму, и конкурировать за единственный ключ журнала.

Решение: использовать уже существующий общий guard на уровне receiving completion. Менять формат
journal или добавлять новый lock не требуется. Абсолютные снимки сохраняют идемпотентное recovery.

