# Runtime boundary: payment finalization

## Before durable commit

Validate shift, delivery tariff, payment total, delivery cash and stock; create receipt and storage
snapshots. No live product/order/shift mutation and no print or network call may occur here.

## Atomic local commit

Write products, orders, shifts and empty current session under `criticalStorageJournal` recovery.

## After durable commit

Replace live state, clear the order UI, show the receipt, then asynchronously publish loyalty and
print. Failures in these external effects must not erase the local receipt.

## Follow-up boundary

Each externally accepted split part needs a durable local draft before the UI labels it paid.

