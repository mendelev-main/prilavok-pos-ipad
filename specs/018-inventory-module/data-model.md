# Data model: модуль инвентаризации

Этап не меняет persisted-модель. Документ фиксирует существующий контракт совместимости.

## InventoryConfig (`inventoryConfig`)

- `enabled`: включён ли график.
- `frequency`: `weekly`, `monthly` или `quarterly`.
- `productIds`: идентификаторы учитываемых товаров.
- `lastCompletedAt`: время последней плановой инвентаризации.

## InventoryDraft (`inventoryDraft`)

- `id`: локальный идентификатор.
- `type`: `scheduled` или `adhoc`.
- `startedAt`: время начала.
- `scheduledDate`: дата планового окна или начала внеплановой проверки.
- `items`: snapshot позиций инвентаризации.

Состояния: отсутствует → активен → все позиции зафиксированы → перенесён в историю и удалён.

## InventoryItem

- `productId`, `name`, `unit`: snapshot идентификации товара.
- `expected`: учётный остаток на момент фиксации.
- `actual`: введённый фактический остаток.
- `difference`: нормализованная разница.
- `fixedAt`: признак и время необратимой фиксации позиции в рамках черновика.

## InventoryHistoryRecord (`inventoryHistory`)

- Полный snapshot завершённого черновика.
- `completedAt`: время завершения.
- `estimatedLoss`: стоимость недостач по текущей себестоимости во время завершения.

## Инварианты

1. `inventory-fix` атомарно меняет `products` и `inventoryDraft`.
2. `inventory-complete` атомарно сохраняет `products`, `inventoryHistory`, `inventoryConfig` и `inventoryDraft: null`.
3. Runtime-состояние меняется только после успешной критической записи.
4. Фиксированная позиция не редактируется повторно.
5. Старые записи загружаются без добавления или переписывания полей.
