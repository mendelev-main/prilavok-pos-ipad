# Research: payment module boundary

## Selected boundary

Move the contiguous block beginning with payment receipt rendering and ending with
`showPaymentReceipt`. This includes cash/card/split UI, validation, durable split draft, loyalty
precheck, atomic finalization and the paid-receipt modal.

## Consumed APIs

State and formatting, cart totals/discounts, delivery settings, shift totals, stock planning, session
snapshots, critical storage, loyalty allocation/publication, modal/render helpers and printer bridge.

## Excluded APIs

Receipt history modal, returns, general receipt reprint routing, shift flows and `network-printer.js`
remain in their current locations.

## Decision

Use a classic script before startup so existing inline handlers and `loadAll()` recovery keep resolving
the same global function names. The fixture evaluates this exact file.

