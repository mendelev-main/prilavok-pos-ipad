# Runtime Boundary: purchase orders

Classic script `PrilavokPOS/Web/js/features/purchase-orders.js` сохраняет глобальные функции:

- access/delete: `canAdminDeletePurchaseOrder`, `openDeletePurchaseOrderModal`,
  `deletePurchaseOrderAsAdmin`
- units/draft: `purchaseUnitLabel`, `requestedQuantityText`, `purchaseUnitOptions`,
  `makePurchaseLine`, `updatePurchaseRequest`
- create/presentation: `finalizePurchaseOrder`, `purchaseHistoryStatus`, `purchaseHistoryMarkup`,
  `togglePurchaseHistory`, `openPurchaseQuantity`, `purchaseQuantityKey`, `applyPurchaseQuantity`,
  `renderPurchaseOrdersScreen`, `togglePurchasePanel`
- share/view: `getPurchaseOrderSupplier`, `purchaseOrderText`, `selectPurchaseOrderSupplier`,
  `viewPurchaseOrder`, `copyPurchaseOrder`, `sharePurchaseOrder`

Модуль зависит от уже объявленных state/storage/unit/UI helpers и загружается после suppliers,
до receiving drafts/completion и до startup.

