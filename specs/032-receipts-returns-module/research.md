# Research: receipt and return boundary

## Selected boundary

The contiguous block from `showReceipt` through `renderReceiptsScreen` owns receipt viewing, reprint handoff, historical stock restoration, full-return commit and the receipts screen. It depends on `payment.js` for `receiptBodyHtml`, `showPaymentReceipt` and `sendOrderToPrint`, so it loads immediately after payment.

## Confirmed findings

1. Return persistence is already atomic: cloned products/orders/shifts are committed through one critical journal before replacing in-memory state.
2. New receipts restore the exact saved `stockConsumption` snapshot. Old receipts intentionally keep the legacy one-level recipe path.
3. Duplicate return is rejected before mutation and loyalty reversal begins only after the local commit.
4. Drawer balance had double subtraction: returned receipts were removed from `cash`, while the same amount was also included in refund withdrawals.
5. `Number(value || 0)` could turn a stored `NaN` cash amount into zero and permit an inconsistent return.

## Decisions

- Preserve `shiftTotals().cash` as net active cash revenue because shift UI and reports rely on that meaning.
- Add `refundCashMovements` and one `cashDrawerBalance()` helper that neutralizes only the duplicate accounting effect for physical drawer balance.
- Validate return total and cash components before cloning or storage writes.
- Preserve all stored field names and movement records.
