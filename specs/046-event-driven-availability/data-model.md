# Data Model

No new persisted entity is introduced. Existing `webAvailabilityRevision` remains monotonic. Snapshot
items remain `{externalId, quantity}`, where `null` means untracked stock and zero blocks availability.
`settledWebOrderIds` is an additive request field retained in runtime until a successful response.
After restart it is reconstructed from existing paid receipts containing `webOrderId`; no new local
storage key is introduced. The pending generation and active request remain runtime-only state.

Backend adds three isolated entities: latest snapshot state per device, current physical quantity per
external product, and open WEB reservations per order/product. POS product JSON remains unchanged.
`null` physical quantity stays unlimited/untracked. Effective public quantity is physical quantity minus
all unsettled reservations, clamped to zero.
