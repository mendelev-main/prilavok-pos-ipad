# Quickstart: проверка модуля WEB-заказов

## Автоматические проверки

```bash
node --test tests/*.test.cjs
```

Ожидается: весь набор тестов проходит, включая EventSource, принятие, повтор ACK, legacy recovery,
клиента, время готовности, доставку и печать.

## Синтаксис JavaScript

```bash
node --check PrilavokPOS/Web/js/features/web-orders.js
node --check tests/product-stock.test.cjs
```

## Контрольная сборка

```bash
xcodebuild -project PrilavokPOS.xcodeproj -scheme PrilavokPOS \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Ожидается `BUILD SUCCEEDED`; новый файл присутствует внутри ресурса `Web` без изменения
`project.pbxproj`.

## Отложенная физическая приёмка

По согласованному порядку ручные сценарии выполняются единым финальным прогоном: запуск без сети,
получение WEB-заказа, принятие, повтор после сбоя ACK, отсутствие дубля в Отложенных и одна кухонная
печать.

## Результат 2026-10-02

- JavaScript syntax: PASS.
- Node suite: PASS, 209/209.
- Debug iOS Simulator build: `BUILD SUCCEEDED`.
- Собранный bundle содержит `Web/js/features/web-orders.js`.
- `project.pbxproj`, версия, storage-ключи и форматы данных не изменены.
