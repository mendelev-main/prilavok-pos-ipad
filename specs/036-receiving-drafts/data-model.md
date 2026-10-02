# Data Model: черновик приёмки

Существующие формы сохраняются без миграции:

```text
purchaseOrder.receivingDraftV2 {
  version: 1
  orderId: string
  supplierId: string
  invoiceNumber: string
  invoiceDate: string
  lines: ReceivingDraftLine[]
}
purchaseOrder.receivingIncomplete: boolean
prilavok_receivingDraft: тот же draft с orderId = null
```

Legacy `purchaseOrder.receivingDraft` продолжает читаться при первом построении V2. Пустое количество для неизвестной упаковки и явный ноль сохраняются различимо.
