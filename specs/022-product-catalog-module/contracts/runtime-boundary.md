# Runtime boundary: product catalog

## Provided global API

Компонент сохраняет CSV helpers/actions, search/sort helpers, `renderProductsScreen()`,
`filterProductsScreen()` и `clearProductsSearch()`.

Основные точки: `parseProductCSV`, `planProductImport`, `confirmProductImport`,
`productMatchesSearch`, `sortProductsBy`, `sortedProductRows`, `renderProductsScreen`.

## Consumed runtime API

Компонент использует `state`, `PrilavokCore.Storage`, `markStorageBroken`, `uid`, product/category/unit/
cost helpers, modal/render/flash functions, escaping и browser FileReader/DOM APIs. Он загружается до
`loadAll()`.

## Persistent and network contract

- Prefix remains `prilavok_`; logical key remains `products`.
- Existing product fields and defaults remain unchanged.
- Import persists `next` before assigning `state.products`.
- Search and sorting do not write storage.
- No network request or synchronization is introduced.
