# Data Model: чеки и возвраты

No persisted schema changes.

- `order.returnedAt`, `returnedShiftId`, `returnAmount` retain their existing meaning.
- `order.stockConsumption.version === 1` remains the authoritative sold-ingredient snapshot.
- Refund cash movement remains `{type:'withdrawal', subtype:'refund', amount, timestamp, note}`.
- `refundCashMovements` is a derived `shiftTotals` value and is not stored.
- `cashDrawerBalance` is a derived amount and is not stored.
