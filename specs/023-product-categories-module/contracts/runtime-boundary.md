# Runtime boundary: product categories

## Provided global API

Компонент сохраняет category modal/actions, presentation toggles, `limitTileSymbol()`,
`saveCategory()` и `deleteCategory()`.

Основные точки: `openCategoriesModal`, `openCategoryModal`, `selectCategoryColor`,
`limitTileSymbol`, `saveCategory`, `toggleCategoryOnline`, `deleteCategory`.

## Consumed runtime API

Компонент использует `state`, `syncCategoryOrder`, `productCategoryKey`, `saveKey`, shared
`requestDelete`, modal/render/flash helpers, escaping и DOM/Intl APIs. Он загружается до `loadAll()`.

## Persistent and network contract

- Prefix remains `prilavok_`.
- Logical keys remain `products`, `layout`, `posNavigation`.
- Existing object and array shapes remain unchanged.
- No network operation or synchronization is introduced.
- Existing multi-key write order remains unchanged in this extraction.
