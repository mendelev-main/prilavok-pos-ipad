# Research: граница оплаты

## Proven durable path

`finalizePayment` calculates the receipt and stock plan without mutating live state. It commits
`products`, `orders`, `shifts` and an empty `currentOrderSession` through `commitCriticalStorage`.
Only after that commit succeeds does it replace live state, clear the current order, display the
receipt, publish loyalty and schedule printing.

The critical journal covers failure before the first target write and recovery after a partial target
write. `criticalOperationBusy` blocks overlapping critical operations while the commit is in flight.

## Confirmed P1 defect: paid split parts are volatile

`completeSplitPayment` marks a part as paid only in `state._splitPayments`. This transient array is
cleared by `closePaymentPage` and is absent from `currentOrderSession`. A WebView restart also loses
it. The cashier may already have accepted cash or confirmed a card terminal transaction, so reopening
the order presents the full amount as unpaid and can cause double collection or an unrecorded payment.

### Reproduction

1. Open a non-empty order and choose split payment.
2. Complete the first cash or card part.
3. Tap Back or terminate/relaunch the app before completing the last part.
4. Reopen payment: the first paid part is missing and the full receipt total is due again.

### Bounded follow-up

Persist a validated split-payment draft inside the existing `currentOrderSession` record whenever a
part becomes paid, restore it only when it still matches the current cart total, and prevent silent
discard of a draft containing paid parts. Clear it in the same final payment journal. Do this under a
new spec with interruption and compatibility tests.

## Defensive validation gap

`finalizePayment` verifies only that payment amounts sum to the receipt total. Direct runtime calls
could supply unknown methods or offsetting negative and positive amounts. Current UI paths do not
produce those values, so this is not an observed cashier path, but the finalization boundary should
validate its input in the follow-up.

## Other conclusions

- Stock availability is recalculated immediately before persistence.
- Delivery tariff selection and delivery cash availability are rechecked before commit.
- Receipt numbering and order creation occur once per successful finalization path.
- Printer and loyalty failures cannot roll back or block the already saved local sale.
- A failed journal creation leaves cart, stock, shifts and orders unchanged.

