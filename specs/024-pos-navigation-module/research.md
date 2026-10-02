# Research: модуль навигации рабочей зоны

## Existing boundary

The code is one contiguous block between `productCategoryKey` and `renderCartPanel`. It owns normalization, folder CRUD, category/root rendering, tile membership/order, layout editor, pointer drag/drop and workspace search.

## Decision

Move the block byte-for-byte into one classic script loaded after product categories and before startup. Classic script semantics preserve inline-handler globals and the lexical drag state.

## Compatibility evidence

Navigation persists only through logical key `posNavigation`; root layout persists through `layout`. Products are read for membership/rendering but folder operations do not rewrite them. Existing regressions cover restart, invalid legacy values, failed writes, click routing, drag cancellation, backup and modal presentation.
