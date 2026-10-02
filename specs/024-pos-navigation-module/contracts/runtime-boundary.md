# Runtime boundary: POS navigation

## Provided global API

Normalization and queries, folder CRUD/modal actions, workspace render/navigation, layout editor, tile add/remove/reorder, pointer drag handlers and workspace search.

## Consumed runtime API

`state`, `productCategoryKey`, product/stock/cart helpers, storage adapter/facade, modal/render/escape helpers, DOM and pointer APIs.

## Persistent and network contract

- Keys remain `posNavigation` and `layout`.
- Prefix and JSON shapes remain unchanged.
- Folder writes complete before state replacement.
- No network request, timer, synchronization or catalog write is introduced.
- Script loads before `loadAll()`.
