# Runtime boundary: receipts module

## Provided globals

`showReceipt`, `viewReceiptModal`, `restoreOrderStock`, `openReturnConfirm`, `processFullReturn`, `printReceipt`, `selectReceipt` and `renderReceiptsScreen`.

## Consumed globals

Local state, payment receipt renderer, formatting/modal/render helpers, shift totals and drawer balance, critical storage journal, stock helpers, loyalty settlement and printer handoff.

## Load order

`payment.js` → `receipts.js` → remaining feature modules → `loadAll()`.

## Excluded

Payment finalization, shift lifecycle, loyalty transport and native LAN printer implementation remain in their current owners.
