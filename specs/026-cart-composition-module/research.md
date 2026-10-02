# Research: формирование корзины

## Boundary

The block starts at modifier signature/cart identity and ends after `removeFromCart`, immediately
before shared `flash` and parking. It owns manual price, modifier selection, quantity, swipe and
empty-order reset.

## Finding

`cartSwipeState` was read by `handleCartRowClick` before any declaration. Touch paths happened to
assign an implicit global first, while a direct click could throw. The module explicitly initializes
`let cartSwipeState=null`.

## Existing evidence

The suite already covers nested recipes, shared ingredients, modifier aggregation, line merging,
quantity rejection, last-line cleanup and payment durability.
