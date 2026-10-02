# Research: представление текущего заказа

## Boundary

The contiguous block owns cart HTML, discount/subtotal helpers, item option modal and order settings.
It consumes stock validation and session persistence, but does not finalize sales.

## Decision

Move this block byte-for-byte. Keep `cartItemKey`, add-to-cart, modifiers, quantity actions,
parking and payment in `pos.html`. Load after POS navigation and before startup.

## Existing evidence

Delivery tariff tests already exercise `selectDeliveryFee` and session persistence. The full suite
covers payment totals, stock checks, parking, WEB orders, loyalty, printing and receipt durability.
