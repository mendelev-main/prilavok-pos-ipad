# Runtime boundary: inventory

## Provided global API

Компонент сохраняет существующие глобальные точки вызова:

- `inventoryWindow()`, `inventoryNextDate()`, `inventoryDaysUntil()`
- `renderInventoryTopbarReminder()`
- `setInventoryFrequency(value)`, `filterInventoryProducts(value)`, `saveInventorySettings()`
- `startInventory(type)`, `openInventoryWork()`, `startAdhocInventory()`
- `updateInventoryActual(id, value)`, `fixInventoryItem(id)`
- `requestCancelInventory()`, `confirmCancelInventory()`, `pauseInventory()`
- `completeInventory()`, `inventorySummaryData()`, `showInventorySummary()`, `confirmCompleteInventory()`
- `renderInventoryScreen()`, `renderInventoryWorkScreen()`

## Consumed runtime API

Компонент использует существующие `state`, `saveKey`, `storageSnapshot`, `commitCriticalStorage`,
`criticalOperationBusy`, product/unit helpers, admin check, modal/render/flash helpers and escaping.

`pos.html` loads the component after those declarations and before the single `loadAll()` call.

## Persistent contract

- Prefix remains `prilavok_`.
- Keys remain `inventoryConfig`, `inventoryHistory`, `inventoryDraft`, and `products`.
- Journal operation names remain `inventory-fix` and `inventory-complete`.
- No migration, cleanup, normalization write, or network side effect is introduced.

## Failure contract

- Invalid input causes no storage or runtime mutation.
- Failed critical storage commit leaves runtime products and inventory documents unchanged.
- Restart recovery uses the existing shared critical journal.
- Repeated actions while `criticalOperationBusy` do not start a second commit.
