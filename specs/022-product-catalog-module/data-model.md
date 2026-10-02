# Data Model: каталог товаров

## CSV Entry

- `name`: исходное название.
- `category`: необязательное название категории.
- `price`: число либо `null`.

## Import Plan

- `add`: нормализованные новые товары перед назначением совместимых defaults.
- `skipped`: имена существующих товаров или дублей.

## Imported Product

Сохраняет прежние поля: `id`, `name`, `category`, `type`, `price`, `cost`, `stock`,
`noStockTracking`, `availableOnline`, `imageUrl`, `tileSymbol`, `sortOrder`.

## Catalog View State

- `productsSearch`: runtime query.
- `_productsSort`: runtime `{key, direction}`.

## Persistence

Используется только существующий logical key `products` через storage adapter. Поиск и сортировка
не записываются. Новых ключей и обязательных полей нет.
