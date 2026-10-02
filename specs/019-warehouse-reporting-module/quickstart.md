# Quickstart: проверка модуля складской аналитики

## Syntax and automated regression

```bash
node --check PrilavokPOS/Web/js/features/warehouse-reporting.js
node --check tests/product-stock.test.cjs
node --test tests/*.test.cjs
```

Ожидается полный PASS складских расчётов, legacy boundaries, selected sections и PDF/XLSX routing.

## Simulator build

```bash
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath /tmp/mpos-derived-019 build
```

Ожидается `BUILD SUCCEEDED`; bundle содержит `Web/js/features/warehouse-reporting.js`.

## Отложенная физическая приёмка

В общем финальном прогоне: открыть складской учёт, проверить периоды, секции, сформировать и визуально
проверить PDF/XLSX, затем проверить ежемесячный Telegram PDF на реальном iPad.

## Результат 2026-10-02

- JavaScript syntax: PASS.
- Node suite: PASS, 211/211.
- Warehouse calculation/export scenarios: PASS, 14/14.
- Debug iOS Simulator build: `BUILD SUCCEEDED`.
- Собранный bundle содержит `Web/js/features/warehouse-reporting.js`.
- Версия, `project.pbxproj`, storage и native payload не изменены.
