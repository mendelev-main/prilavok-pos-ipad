# Quickstart: проверка модуля зала и бронирований

```bash
node --check PrilavokPOS/Web/js/features/hall-bookings.js
node --check tests/product-stock.test.cjs
node --test tests/*.test.cjs
```

Затем выполнить Simulator build с отдельным DerivedData path и проверить наличие
`Web/js/features/hall-bookings.js` внутри `.app`.

Физическая проверка в финальном прогоне: создание и drag стола, rotation, новая/редактированная/
отменённая бронь, запрет пересечения, каскадное удаление и сохранность после перезапуска.

## Результат 2026-10-02

- JavaScript syntax: PASS.
- Node suite: PASS, 214/214.
- Hall/bookings runtime scenarios: PASS, 3/3.
- Побайтовое сравнение перенесённого production-блока: PASS.
- Debug iOS Simulator build: `BUILD SUCCEEDED`.
- Собранный bundle содержит `Web/js/features/hall-bookings.js` с идентичным SHA-256.
- Версия, `project.pbxproj`, storage keys и JSON-форматы не изменены.
