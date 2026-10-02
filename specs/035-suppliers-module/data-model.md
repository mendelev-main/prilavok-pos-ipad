# Data Model: поставщики

Сохраняется существующий массив `prilavok_suppliers`.

```text
Supplier {
  id: string
  name: string
  productIds: string[]
  ...unknown legacy fields preserved on edit
}
```

`purchaseOrders` и `receivings` содержат исторические `supplierId`/`supplierName` и не меняются при редактировании или удалении справочника.
