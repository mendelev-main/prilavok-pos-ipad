# Quickstart: проверка модуля категорий товаров

```bash
node --check PrilavokPOS/Web/js/features/product-categories.js
node --check tests/product-stock.test.cjs
node --test tests/*.test.cjs
```

Затем выполнить Simulator build с отдельным DerivedData path и проверить наличие
`Web/js/features/product-categories.js` внутри `.app`.

Физическая проверка в финальном прогоне: список категорий, создание, редактирование имени/цвета/
обозначения/WEB, блокировка удаления непустой категории и удаление пустой категории с паролем.

## Результат 2026-10-02

- JavaScript syntax: PASS.
- Node suite: PASS, 222/222.
- Product category scenarios: PASS, 4/4.
- Побайтовое сравнение перенесённого production-блока: PASS.
- Debug iOS Simulator build: `BUILD SUCCEEDED`.
- Собранный bundle содержит `Web/js/features/product-categories.js` с идентичным SHA-256.
- Версия, `project.pbxproj`, storage keys и JSON-форматы не изменены.
