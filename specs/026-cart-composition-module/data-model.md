# Data Model: cart composition

Existing cart line shape is preserved: `cartLineId`, `productId`, `name`, `price`,
`basePrice`, optional `manualPrice`, `qty`, `selectedModifiers`, comment and discount reference.

Empty-cart reset continues to clear order label/type, customer, loyalty selections, delivery fields,
WEB context and kitchen-print state through the existing session helpers. No migration is introduced.
