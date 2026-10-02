# Quickstart: проверка модуля аналитики

```bash
node --check PrilavokPOS/Web/js/features/analytics.js
node --check tests/product-stock.test.cjs
node --test tests/*.test.cjs
```

Затем выполнить Simulator build с отдельным DerivedData path и проверить наличие
`Web/js/features/analytics.js` внутри `.app`.

Физическая проверка в финальном прогоне: периоды Сегодня/7/30 дней, произвольные даты, KPI
администратора и сотрудника, диаграммы, loyalty online/offline и переход в складской учёт.

## Результат 2026-10-02

- JavaScript syntax: PASS.
- Node suite: PASS, 217/217.
- Analytics runtime scenarios: PASS, 3/3.
- Побайтовое сравнение перенесённых production-блоков: PASS.
- Debug iOS Simulator build: `BUILD SUCCEEDED`.
- Собранный bundle содержит `Web/js/features/analytics.js` с идентичным SHA-256.
- Версия, `project.pbxproj`, storage keys и JSON-форматы не изменены.
