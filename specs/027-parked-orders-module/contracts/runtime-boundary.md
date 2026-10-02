# Runtime boundary: parked orders

## Provided global API

Kitchen line identity/delta helpers, park prompt/action, parked list modal, resume and delete.

## Consumed runtime API

Current cart/session state, critical journal, product/employee lookup, totals, modal/render/flash,
kitchen print bridge, loyalty reload and formatting helpers.

## Excluded critical paths

Payment UI, payment validation, receipt finalization, stock mutation, returns and loyalty sale/reversal
remain in the main runtime.
