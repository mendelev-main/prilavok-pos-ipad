# Runtime boundary: cart composition

## Provided global API

Cart identity/signature, add-to-cart, manual price, modifier selection, quantity changes, row click
and touch handlers, order reset and line removal.

## Consumed runtime API

Product lookup, modifier normalization, aggregate stock validation, session persistence, cart item
modal, modal/render/escape/format helpers and DOM APIs.

## Excluded critical paths

Shared notifications, parking/resume, kitchen printing, payment, receipt creation, stock mutation,
returns and loyalty publication remain outside this component.
