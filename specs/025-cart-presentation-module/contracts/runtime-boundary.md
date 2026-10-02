# Runtime boundary: current order presentation

## Provided global API

`renderCartPanel`, discount/subtotal helpers, cart item option modal/actions, order settings,
order type and delivery tariff selection.

## Consumed runtime API

State, formatting/escaping, cart identity, stock validation, loyalty total, delivery validation,
modal/render helpers and `saveCurrentOrderSession`.

## Excluded critical paths

Product addition, modifier selection, quantity swipe/actions, parking, payment, finalization,
stock mutation, receipts and printing remain outside this component.
