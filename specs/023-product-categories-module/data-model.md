# Data Model: категории товаров

## Category Order

Массив строк `categoryOrder`; имя является текущей ссылкой для товаров и UI.

## Category Presentation

- `categoryColors[name]`: цвет.
- `categorySymbols[name]`: до трёх Unicode grapheme.
- `categoryOnline[name]`: boolean публикации.

## Related References

- Product: `product.category`.
- Navigation entry: `posNavigation.categories[].category`.
- Layout tile: `{type: 'category', id: name}`.

## Persistence

Используются только существующие logical keys `products`, `layout`, `posNavigation` через `saveKey`.
Новых ключей, полей или миграции нет.
