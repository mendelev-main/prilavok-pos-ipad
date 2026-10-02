# Runtime Boundary Contract

`Web/js/features/suppliers.js` сохраняет прежние globals:

- `openSupplierModal`
- `filterSupplierProducts`
- `deleteSupplier`, `confirmDeleteSupplier`
- `saveSupplier`

Модуль загружается после shift/access helpers и до `loadAll()`. Он использует существующие `state`, `canEditCompanySettings`, storage adapter и modal helpers.
