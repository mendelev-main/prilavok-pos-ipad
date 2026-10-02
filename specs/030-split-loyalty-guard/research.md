# Research: split loyalty guard

## Confirmed inconsistency

Cash and card call `beginPaymentWithLoyaltyGuard` before finalization. `openSplitPayment` currently
creates parts immediately, so a selected gift can reduce the split total without the same server
check. Later loyalty publication may discover stale data only after money was accepted.

## Decision

Guard only creation of a new unpaid split. On success, calculate parts from the current confirmed
total. On offline continuation, clear redemptions first and recalculate. A restored draft with paid
parts retains its durable total and does not contact the server again.

