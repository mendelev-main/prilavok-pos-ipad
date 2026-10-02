# Runtime Boundary: receiving completion

Classic script `PrilavokPOS/Web/js/features/receiving.js` сохраняет глобальные функции:

- `invoiceReceivingItems`
- `receivingStockUpdates`
- `receivingDiscrepancy`
- `confirmReceivingDocument`
- `applyReceivingDocument`
- `openPurchaseOrderReceivingModal`
- `finalizePurchaseOrderReceiving`
- `finalizeReceiving`

Модуль использует существующие `state`, UI helpers, unit helpers, `storageSnapshot`,
`commitCriticalStorage`, `criticalOperationBusy` и модуль `receiving-drafts.js`. Новых сетевых
вызовов, таймеров и storage keys нет.

