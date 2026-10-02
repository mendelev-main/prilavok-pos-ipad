# Quickstart: проверка модуля каталога товаров

```bash
node --check PrilavokPOS/Web/js/features/product-catalog.js
node --check tests/product-stock.test.cjs
node --test tests/*.test.cjs
```

Затем выполнить Simulator build с отдельным DerivedData path и проверить наличие
`Web/js/features/product-catalog.js` внутри `.app`.

Физическая проверка в финальном прогоне: CSV picker/preview/confirm/cancel, существующий каталог,
поиск по имени и категории, очистка поиска, все заголовки сортировки и открытие карточки товара.

## Результат 2026-10-02

- JavaScript syntax: PASS.
- Node suite: PASS, 218/218.
- Product catalog scenarios: PASS, 13/13, включая 12 прежних regression-тестов.
- Побайтовое сравнение перенесённого production-блока: PASS.
- Debug iOS Simulator build: `BUILD SUCCEEDED`.
- Собранный bundle содержит `Web/js/features/product-catalog.js` с идентичным SHA-256.
- Версия, `project.pbxproj`, storage key и JSON-формат товаров не изменены.
