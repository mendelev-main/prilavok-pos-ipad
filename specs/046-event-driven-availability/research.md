# Research

## Existing behavior

The current scheduler sends a complete persisted availability snapshot every ten minutes and reschedules
when the app becomes visible. `availabilityBusy` rejects a second trigger, so a payment occurring during
an active request can be lost until the next timer.

## Confirmed commit points

- `payment.js`: after critical payment journal commits products/order/shift/session.
- `receipts.js`: after critical full-return commit restores products.
- `receiving.js`: after critical receiving commit publishes weighted stock/cost.
- `inventory.js`: after each critical fixed-item commit and completion.
- `product-persistence.js`: after direct durable `products` write.

## Decision

Use one pending flag and one drain promise. Each network attempt rereads persisted products. Do not keep
a retry outbox: the user accepts stale WEB availability while offline and wants the next stock-changing
operation with connectivity to refresh it.

## Backend boundary

The iPad sends `{version, revision, sampledAt, items:[{externalId,quantity}]}`. Preventing oversell also
requires backend order creation to validate the latest snapshot. No backend checkout or authenticated
GitHub connection is available in this workspace, so this stage can only guarantee the POS publisher.
