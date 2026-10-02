# Research: durable split payment

## Decision

Store `paymentDraft` as an optional versioned field in `currentOrderSession`. This avoids a new key and
lets old records remain valid. The draft is useful only after at least one part has been externally
accepted.

## Commit order

1. Clone and validate the proposed split parts.
2. Build a full current-session snapshot with `paymentDraft`.
3. Commit that session through the critical journal.
4. Replace live split state and render «Оплачено».
5. When all parts are paid, run the existing atomic receipt finalization.

## Recovery

Accept the draft only when its version, method allowlist, amounts, total cents and cash metadata are
valid and its total still equals the current order. A valid draft reopens the split payment screen.
Invalid optional data is ignored and marks storage unhealthy without overwriting source bytes.

