# Quickstart: проверка модуля инвентаризации

## JavaScript syntax

```bash
node --check PrilavokPOS/Web/js/features/inventory.js
node --check tests/product-stock.test.cjs
```

## Automated regression

```bash
node --test tests/*.test.cjs
```

Ожидается полный PASS, включая failure, atomic commit и restart recovery сценарии инвентаризации.

## Simulator build

```bash
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath /tmp/mpos-derived-018 build
```

Ожидается `BUILD SUCCEEDED`, а собранный bundle содержит `Web/js/features/inventory.js`.

## Отложенная физическая приёмка

В общем финальном прогоне: открыть сохранённый черновик, выполнить плановую и внеплановую
инвентаризацию, проверить права отмены, фиксацию каждой позиции, итоговую историю и остатки после
перезапуска приложения.

## Результат 2026-10-02

- JavaScript syntax: PASS.
- Node suite: PASS, 210/210.
- Inventory atomicity and recovery scenarios: PASS, 6/6.
- Debug iOS Simulator build: `BUILD SUCCEEDED`.
- Собранный bundle содержит `Web/js/features/inventory.js`.
- Версия, `project.pbxproj`, storage-ключи и persisted-форматы не изменены.
