# Runtime boundary: payment module

## Provided globals

Payment screen/keypad helpers, split calculation and persistence helpers, loyalty payment guard,
`finalizePayment`, paid receipt rendering and the compatibility aliases for cash/card payment.

## Consumed globals

Cart/order state, delivery and stock validation, critical storage/session snapshots, receipt/shift
helpers, loyalty functions, modal/render/format helpers and printer entry points.

## Excluded

Receipt history, return processing, shift lifecycle and printer routing implementation.

